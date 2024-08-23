create procedure cluster
  @rootName VARCHAR (8000),
  @rootID INT,
  @rootGroup INT
  as begin
  --table to hold connected component for a cluster
  DECLARE @connected TABLE (
  myName VARCHAR (8000),
  myID INT,
  myGroup INT,
  PRIMARY KEY (myID)
  )




  --insert root
  INSERT INTO @connected (myName, myID, myGroup)
  VALUES (@rootName, @rootID, @rootGroup);




  --variables to hold current and previous size of the table var
  DECLARE @currSize INT
  DECLARE @prevSize INT
  SET @currSize = 1
  SET @prevSize = 0




  -- while the size is still going, keep looping
  WHILE (@currSize != @prevSize)
      begin
          --update the size
          SET @prevSize = @currSize




          --insert all the nodes that the root has an edge with root node
          INSERT INTO @connected (myID, myGroup)
          SELECT e.citedPaperID, @rootGroup
          FROM @connected c,edges e
          WHERE e.paperID = c.myID AND NOT EXISTS (
              SELECT 1 FROM @connected c WHERE c.myID = e.citedPaperID
          )
          UNION
          SELECT e.paperID, @rootGroup
          FROM @connected c2, edges e
          WHERE e.citedPaperID = c2.myID AND NOT EXISTS (
              SELECT 1 FROM @connected c2 WHERE c2.myID = e.paperID
          )








          UPDATE c3
          SET c3.myName = n.paperTitle
          FROM @connected c3, nodes n
          WHERE c3.myID = n.paperID




          --update current size
          SET @currSize = (SELECT COUNT(*) FROM @connected);
      end




      --add the connected component to the the result
      INSERT INTO #resultSet (myName, myID, myGroup)
      SELECT c.myName, c.myID, c.myGroup
      FROM @connected c
      WHERE NOT EXISTS (
          SELECT 1 FROM #resultSet r WHERE r.myID = c.myID
      )








      --remove all the nodes that were added from the temporary nodes
      DELETE FROM #tempNodes
      WHERE myID IN (SELECT myID FROM @connected)
end


create procedure find
   as begin
-- temporary table to hold all unseen nodes
CREATE TABLE #tempNodes (
  myName VARCHAR (8000),
  myID INT,
  PRIMARY KEY (myID)
  )




-- Initialize temporary table with all the nodes
INSERT INTO #tempNodes (myName, myID)
SELECT paperTitle, paperID
FROM nodes




-- solution table to hold result
CREATE TABLE #resultSet (
  myName VARCHAR (8000),
  myID INT,
  myGroup INT,
  PRIMARY KEY (myID)
  )


-- declare number to categorize each cluster
DECLARE @groupNum INT
-- set intial group number
SET @groupNum = 1




--variable to hold root node
DECLARE @paperID INT
DECLARE @paperName VARCHAR (8000);




--variable to keep track of row in temp table
DECLARE @RowCount INT




-- Initialize the row count
SELECT @RowCount = COUNT(*) FROM #tempNodes








-- Loop as long as there are rows in the table
WHILE (@RowCount > 0)
BEGIN
  --select first root node name arbitrarily
  SELECT TOP 1 @paperName = myName
  FROM #tempNodes
  ORDER BY myID
  --select same first root node ID
   SELECT TOP 1 @paperID = myID
   FROM #tempNodes
  ORDER BY myID




  --INSERT INTO #resultSet (myName, myID, myGroup)
  --VALUES (@paperName, @paperID, @groupNum);




  execute cluster
      @rootName = @paperName,
      @rootID =  @paperID,
      @rootGroup = @groupNum




  SET @groupNum = @groupNum + 1




  --update value of row count after deletion
  SELECT @RowCount = COUNT(*) FROM #tempNodes
end;




--create a view of group number and how many have that group number as size
-- select group name, id , paper name from result table where size > 4 and <11




SELECT r.myName, r.myID, c.myGroup
FROM (
  SELECT myGroup
  FROM #resultSet
  GROUP BY myGroup
  HAVING COUNT(myID) > 4 AND COUNT(myID) < 11
) AS c, #resultSet r
WHERE c.myGroup = r.myGroup;


end


execute find


