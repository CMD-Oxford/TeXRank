function rsdata = getDataFromCRYSTAL(term,type, conn)
% Term - depending on type. See code below.
% type: takes the following values:
%   'InspectIDAndImageName': outputs the following cell with following cols
%           inspectid | barcode | inspectNo | inspectdate | col | row | subwell | imagename
%           sorted by col-row-subwell, giving 1:288 as in imagenames
%   'MaxScoreID': returns max score of in i_scores_jtng
%   'ValidPlateInspections': find all inspections that were scored, given a barcode
%           scored inspections | screen type
%   'ScoresByBarcodeAndInspection'
%           return scores of a plate (in score_type format) (288x1 cell, string).
% Remember to javaaddpath('P:\ojdbc5.jar');
    
% 
if nargin < 3
    %# connection parameteres
    host = 'YourHost.Domain';
    dbName = 'DatabaseName';
    user = 'Username';
    password = 'YourPassword'; %yes, not ideal to have to spell it out, but if compiled, nobody sees this anyway.
    %# JDBC parameters
    jdbcString = sprintf('jdbc:oracle:thin:@%s:1521:', host);
    jdbcDriver = 'oracle.jdbc.driver.OracleDriver'; % or whichever database you use. 
    
    %# Create the database connection object
    conn = database(dbName, user , password, jdbcDriver, jdbcString);
end
 
if isconnection(conn) % check to make sure that we successfully connected
    switch type
        
        case 'AutoScores'
            qry = ['select a.xtal_rank_score, b.inspectid, c.imagename, a.xtal_clear_score, a.xtal_good_bad_score, b.inspectdate '...
                   'from CRYSTAL.I_AUTOSCORES a, CRYSTAL.I_INSPECTIONS b, CRYSTAL.I_IMAGES c '...
                   'where a.inspectid = b.inspectid and b.inspectid = c.inspectid and b.barcodeid = ''' term{1} ''' and b.inspectnumber = ' num2str(term{2}) ' '... 
                   'order by b.col, b.i_row, b.subwell'];
        case 'ManualScores'
            qry = ['select a.inspectid, a.col, a.i_row, a.subwell, b.score, b.scoredate '...
                   'from CRYSTAL.I_INSPECTIONS a, CRYSTAL.I_SCORES b '...
                   'where a.inspectid = b.inspectid and a.barcodeid = ''' term ''' and b.score!= 20 '...
                   'order by a.col, a.i_row, a.subwell, b.score'];
        case 'InspectionsForABarcode'
            qry = ['select inspectnumber, dropviewcount from CRYSTAL.i_plate_inspections '...
                'where barcodeid = ''' term ''''];
        case 'ListOfProjects'
            qry = 'select name from CRYSTAL.projects order by (name)';
        case 'ListOfBarcodesForGivenProject'
            qry = ['select distinct a.barcode, c.sample_name, a.setup_date, max(e.dropscorecount), a.plate_name '...
                   'from CRYSTAL.plates a, CRYSTAL.plate_drops b, CRYSTAL.samples c, CRYSTAL.projects d, CRYSTAL.I_PLATE_INSPECTIONS e '...
                   'where d.name = ''' term ''' and a.project_id = d.project_id '...
                   'and b.fk_plate_id = a.plate_id '...
                   'and e.barcodeid = a.barcode '...
                   'and c.sample_id = b.fk_sample_id and a.barcode like ''CI%'' '...
                   'group by a.barcode, c.sample_name, a.setup_date, a.plate_name '...
                   'order by a.setup_date desc'];
        case 'ListOfBarcodesForGivenProject_MaxDropViewCount'
            qry = ['select max(e.dropviewcount) '...
                   'from CRYSTAL.plates a, CRYSTAL.plate_drops b, CRYSTAL.samples c, CRYSTAL.projects d, CRYSTAL.I_PLATE_INSPECTIONS e '...
                   'where d.name = ''' term ''' and a.project_id = d.project_id '...
                   'and b.fk_plate_id = a.plate_id '...
                   'and e.barcodeid = a.barcode '...
                   'and c.sample_id = b.fk_sample_id and a.barcode like ''CI%'' '...
                   'group by a.barcode, c.sample_name, a.setup_date, a.plate_name '...
                   'order by a.setup_date desc'];
        case 'ListOfBarcodesOrderByLastInspection'
            qry = ['select distinct a.barcode, max(e.inspectdate) '...
                   'from CRYSTAL.plates a, CRYSTAL.projects d, CRYSTAL.I_PLATE_INSPECTIONS e '...
                   'where d.name = ''' term ''' and a.project_id = d.project_id '...
                   'and e.barcodeid = a.barcode and a.barcode like ''CI%'' '...
                   'group by a.barcode order by max(e.inspectdate) desc'];
        case 'ImageNamesForPlateAndInspection'
            qry = ['select b.imagename, b.inspectid, a.inspectdate from CRYSTAL.i_inspections a, CRYSTAL.i_images b '...
                   'where a.inspectid = b.inspectid and a.barcodeid = ''' term{1} ''' and a.inspectnumber = ' num2str(term{2}) ' '...
                   'order by a.col, a.i_row, a.subwell'];

        case 'Custom'
            qry = term;
               
    end
    rs = fetch(exec(conn, qry));
    rsdata = get(rs, 'Data');
    close(rs);
    
    
    
   
end
if nargin < 3
    close(conn);
end
end

