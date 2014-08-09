function rsdata = getDataFromBEEHIVE(term,type, conn)
%# connection parameteres
if nargin < 3
    host = 'YourHost.domain';
    dbName = 'DatabaseName';
    user = 'YourUserID';
    password = 'YourPassword'; %yes, not ideal to have to spell it out, but if compiled, nobody sees this anyway.
    %# JDBC parameters
    jdbcString = sprintf('jdbc:oracle:thin:@%s/%s', host, dbName);
    jdbcDriver = 'oracle.jdbc.driver.OracleDriver'; % or whichever database you use. 

    %# Create the database connection object
    conn = database(dbName, user , password, jdbcDriver, jdbcString);
end
if isconnection(conn) % check to make sure that we successfully connected
    switch type
        case 'ScreenConditionsGivenPlate'
            qry = ['SELECT  /*+ CHOOSE */ SGC.XTAL_PLATES.BARCODE, SGC.XTAL_SCREENID.SCREENNAME, SGC.XTAL_SCREENCONDITIONS.PLATECOLUMN, SGC.XTAL_SCREENCONDITIONS.PLATEROW, SGC.XTAL_SCREENCONDITIONS.WELLDESCRIPTION '...
                   'FROM SGC.XTAL_PLATES, SGC.XTAL_SCREENBATCH, SGC.XTAL_SCREENCONDITIONS, SGC.XTAL_SCREENID '...
                   'WHERE (  SGC.XTAL_PLATES.BARCODE = ''' term ''' ) AND SGC.XTAL_SCREENBATCH.PKEY=SGC.XTAL_PLATES.SGCXTALSCREENBATCH_PKEY(+) AND SGC.XTAL_SCREENBATCH.SGCXTALSCREENID_PKEY=SGC.XTAL_SCREENCONDITIONS.SGCXTALSCREENID_PKEY(+) AND SGC.XTAL_SCREENID.PKEY=SGC.XTAL_SCREENBATCH.SGCXTALSCREENID_PKEY '...
                   'ORDER BY SGC.XTAL_SCREENCONDITIONS.PLATECOLUMN NULLS LAST, SGC.XTAL_SCREENCONDITIONS.PLATEROW NULLS LAST'];
        case 'PurificationIdAndCompoundIdByPlate'
            qry = ['SELECT  /*+ CHOOSE */ SGC.PURIFICATION.PURIFICATIONID, SGC.V_COMPOUND_XTALPLATE.COMPOUND_ID, SGC.V_COMPOUND_XTALPLATE2.COMPOUND_ID, SGC.XTAL_PLATES.CONCENTRATRION, SGC.XTAL_PLATES.TEMPERATURE, SGC.XTAL_PLATES.DATEPLATECREATED '...
                   'FROM SGC.PURIFICATION, SGC.V_COMPOUND_XTALPLATE, SGC.V_COMPOUND_XTALPLATE2, SGC.XTAL_PLATES '...
                   'WHERE (  SGC.XTAL_PLATES.BARCODE = ''' term ''' ) AND SGC.PURIFICATION.PKEY=SGC.XTAL_PLATES.SGCPURIFICATION_PKEY(+) AND SGC.XTAL_PLATES.SGCCOMPOUND_PKEY=SGC.V_COMPOUND_XTALPLATE.PKEY(+) AND SGC.XTAL_PLATES.SGCCOMPOUND_PKEY2=SGC.V_COMPOUND_XTALPLATE2.PKEY(+)'];
        case 'SynchrotronTrip'
            qry = 'select * from (select T1."TRIP" "Trip", T1."TRIPDATE" "Trip Date" from DUAL ONE_ROW_TAB_ inner join "SGC"."V_XTALTRIPS" T1 on T1."TRIPDATE" > ((sysdate) + ((- 1))) order by T1."TRIPDATE")';
        case 'Custom'
            qry = term;
    end
    rs = fetch(exec(conn, qry));
    rsdata = get(rs, 'Data');
    close(rs);
end

if nargin < 3 % only close connection for single instances (ie not used in GUI) 
    close(conn);
end
end