create procedure pagerank
   as begin
--table to hold all page rank
CREATE TABLE #pagerank (
myName VARCHAR (8000),
myID INT,
myRank FLOAT,
PRIMARY KEY (myID)
)




--add all the nodes into page rank to keep track of rank
INSERT INTO #pagerank (myName, myID)
SELECT n.paperTitle, n.paperID
FROM nodes n




--set the intial page rank for all papers
UPDATE #pagerank
SET myRank = 1.0/(SELECT COUNT(*) FROM #pagerank)




--table to hold previous rank
CREATE TABLE #oldrank (
myID INT,
myRank FLOAT,
PRIMARY KEY (myID)
)




--copy from pagerank to intialize
INSERT INTO #oldrank (myID, myRank)
SELECT pr.myID, pr.myRank
FROM #pagerank pr




--table to hold page rank for sink nodes
CREATE TABLE #sinkrank (
myID INT,
myRank FLOAT,
PRIMARY KEY (myID)
)




--add all the sink nodes
INSERT INTO #sinkrank (myID, myRank)
SELECT pr.myID, pr.myRank
FROM #pagerank pr
WHERE  pr.myID NOT IN (SELECT distinct e.paperID from edges e)




--table to hold edge probabilites
CREATE TABLE #edgeprob (
myID INT,
citedID INT,
prob FLOAT
PRIMARY KEY (myID, citedID)
)




--add all the edges into edge prob to keep track of edge prob
INSERT INTO #edgeprob (myID, citedID)
SELECT e.paperID, e.citedPaperID
FROM edges e




--set the initial edge probabilities
UPDATE ep
SET ep.prob = pr.myRank/(SELECT COUNT(*)
                      from #edgeprob ep2 WHERE ep2.myID = ep.myID)
FROM #edgeprob ep, #pagerank pr
WHERE ep.myID = pr.myID








--keep track of difference
DECLARE @currDiff FLOAT




SELECT @currDiff = 1




--update page rank
WHILE ((@currDiff) > 0.01)
 begin




     --update the page rank
      UPDATE pr
     SET pr.myRank = ((0.15)/(SELECT COUNT(*) FROM #pagerank))
              + .85*(
              (SELECT SUM(myRank) FROM #sinkrank)/(SELECT COUNT(*) FROM #pagerank)
              + (SELECT ISNULL(SUM(ep2.prob),0) FROM #edgeprob ep2 WHERE ep2.citedID = pr.myID))
      FROM #pagerank pr




     --update the sink nodes paper ranks
     UPDATE sr
     SET sr.myRank = pr.myRank
     FROM #sinkrank sr, #pagerank pr
     WHERE  pr.myID = sr.myID




     --update the edge probabilities after changing the paper ranks
     UPDATE ep
     SET ep.prob = pr.myRank/
                   (SELECT COUNT(*) from #edgeprob ep2 WHERE ep2.myID = ep.myID)
     FROM #edgeprob ep, #pagerank pr
     WHERE ep.myID = pr.myID




     --update the difference
     SELECT @currDiff = SUM(abs(pr.myRank - ork.myRank))
      FROM #pagerank pr, #oldrank ork
      WHERE ork.myID = pr.myID;




     --update the old rank
     UPDATE ork
     SET ork.myRank = pr.myRank
     FROM #oldrank ork, #pagerank pr
     WHERE ork.myID = pr.myID


 end


--select top 10
SELECT TOP 10 *
FROM #pagerank
ORDER BY myRank DESC


end


execute pagerank
