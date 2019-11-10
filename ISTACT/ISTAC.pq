[Version = "1.0.0"]
section ISTAC;

[DataSource.Kind="ISTAC", Publish="ISTAC.Publish"]
shared ISTAC.Contents =  Value.ReplaceType(Navigation, NavigationType);

NavigationType = type function () as table meta [                  
        Documentation.Name = "ISTAC – Datos y metadatos",
        Documentation.LongDescription = "Returns a table with key data from the ISTAC Data API",
        Documentation.Examples = {[
            Description = "Returns a table with key data from the ISTAC Data API",
            Code = "ISTAC.Contents () ",
            Result = "A table with key ISTAC Data API data"
        ]}
    ];

 Navigation = () =>
    let
        objects = #table(
            {"Name",       "Key",        "Data",                           "ItemKind", "ItemName", "IsLeaf"},{
            {"Indicadores",      "indicators",  ISTAC.IndicatorNavTable() , "Folder",    "Indicator",    false},
            {"Cubos",      "Cubos",  ISTAC.Cubos(), "Folder",    "Cubos",    false},
            {"Recursos Estructurales",      "Clasificaciones",  null, "Folder",    "Clasificaciones",    false}
            }),
        NavTable = Table.ToNavigationTable(objects, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf") 
    in
        NavTable;

ISTAC.IndicatorNavTable = ()=> 
      let
        objects = #table(
            {"Name",       "Key",        "Data",                           "ItemKind", "ItemName", "IsLeaf"},{
            {"Indicadores",      "indicators",  ISTAC.Indicadores() , "Folder",    "Indicator",    false},
            {"Sistemas de Indicadores", "SystemIndicators", ISTAC.SystemIndicators(), "Folder", "SystemIndicators", false}, 
            {"Valores auxiliares",      "Auxiliares",  ISTAC.IndicadoresValoresAuxiliares(), "Folder",    "Auxiliares",    false}
            }),
        NavTable = Table.ToNavigationTable(objects, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf") 
    in
        NavTable;

ISTAC.IndicadoresValoresAuxiliares = () =>
    let 
            objects = #table(  {"Name",       "Key",        "Data",                           "ItemKind", "ItemName", "IsLeaf"},{
            {"Geográficos",      "Geográficos",  ISTAC.IndicatorGeographicGranularities() , "Table",    "Geográfico",    true},
            {"Temas", "Temas", ISTAC.IndicatorSubjects(), "Table", "Temas", true},
            {"Tiempo",      "Tiempo",  ISTAC.IndicatorTimeSeries(), "Table",    "Tiempo",    true}
            }),
              NavTable = Table.ToNavigationTable(objects, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf") 
              in 
                  NavTable;

ISTAC.Indicadores = () as table =>
 let
    Source = Json.Document(Web.Contents("https://www3.gobiernodecanarias.org/istac/api/indicators/v1.0/indicators?limit=1000")),
    items = Source[items],
    Custom1 = Table.FromRecords( items, null, MissingField.UseNull ),
    #"Expanded title" = Table.ExpandRecordColumn(Custom1, "title", {"es", "en", "__default__"}, {"title.es", "title.en", "title.__default__"}),
    #"Expanded subjectTitle" = Table.ExpandRecordColumn(#"Expanded title", "subjectTitle", {"es", "__default__"}, {"subjectTitle.es", "subjectTitle.__default__"}),
    #"Grouped Rows" = Table.Group(#"Expanded subjectTitle", {"subjectTitle.es", "subjectCode"}, {{"Data", each _, Value.Type(#"Expanded subjectTitle")  }}),
    #"Renamed Columns" = Table.RenameColumns(#"Grouped Rows",{{"subjectTitle.es", "Name"}, {"subjectCode", "Key"}}),
    #"Added Custom" = Table.AddColumn(#"Renamed Columns", "Custom", each Table.AddColumn([Data],"Data",each TransformBinary.Indicadores([selfLink]) )),
    #"Removed Columns" = Table.RemoveColumns(#"Added Custom",{"Data"}),
    #"Added Custom1" = Table.AddColumn(#"Removed Columns", "ItemKind", each "Folder"),
    #"Duplicated Column" = Table.DuplicateColumn(#"Added Custom1", "Name", "ItemName"),
    #"Added Custom2" = Table.AddColumn(#"Duplicated Column", "IsLeaf", each false),
    #"Renamed Columns1" = Table.RenameColumns(#"Added Custom2",{{"Custom", "Data"}}),
    #"Reordered Columns" = Table.ReorderColumns(#"Renamed Columns1",{"Key", "Name", "ItemKind", "Data", "ItemName", "IsLeaf"}),
    AddSubNavTable = Table.AddColumn(#"Reordered Columns", "NewColumn", each  IndicatorSubTables ([Data] )),
    RemoveOldDataColumn = Table.RemoveColumns( AddSubNavTable, {"Data"}),
    ChangeName = Table.RenameColumns( RemoveOldDataColumn, {"NewColumn", "Data"}),
    ToNavTable = Table.ToNavigationTable( ChangeName, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
in
     ToNavTable ;

IndicatorSubTables = (x as table) => 
    let
           #"Renamed Columns" = Table.RenameColumns(x,{{"id", "Key"}, {"code", "Name"}}),
    #"Added Custom" = Table.AddColumn(#"Renamed Columns", "ItemKind", each "Table"),
    #"Duplicated Column" = Table.DuplicateColumn(#"Added Custom", "Name", "ItemName"),
    #"Added Custom1" = Table.AddColumn(#"Duplicated Column", "IsLeaf", each true),
    #"Removed Other Columns" = Table.SelectColumns(#"Added Custom1",{"Key", "Name", "Data", "ItemKind", "ItemName", "IsLeaf"}),
    ToNavTable = Table.ToNavigationTable( #"Removed Other Columns", {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
    in 
        ToNavTable;

ISTAC.AlternatePagination = (url as text, selector as text ) as table =>
let
Source = List.Generate( ()=> 
[JsonFile = Json.Document(  Web.Contents(url,[Headers=[Accept="application/json"]]) ), nextPage = JsonFile[nextLink]? ],
each [JsonFile] <> null, 
each [JsonFile = try Json.Document( Web.Contents([nextPage],[Headers=[Accept="application/json"]])) otherwise null , nextPage =try Record.Field(JsonFile, "nextLink") otherwise null  ],
each Record.Field([JsonFile], selector )),
    Custom1 = Table.FromRecords(  List.Combine( Source ), null, MissingField.UseNull)
in
    Custom1;

ISTAC.Cubos = ()=>
    let
    Source = ISTAC.AlternatePagination("https://www3.gobiernodecanarias.org/istac/api/statistical-resources/v1.0/datasets?lang=es&limit=1000","dataset"),
    #"Expanded name" = Table.ExpandRecordColumn(Source, "name", {"text"}, {"text"}),
    #"Expanded text" = Table.ExpandListColumn(#"Expanded name", "text"),
    #"Expanded text1" = Table.ExpandRecordColumn(#"Expanded text", "text", {"value", "lang"}, {"value", "lang"}),
    #"Expanded selfLink" = Table.ExpandRecordColumn(#"Expanded text1", "selfLink", {"href"}, {"href"}),
    #"Added Custom" = Table.AddColumn(#"Expanded selfLink", "Custom", each Record.FromList( List.LastN( Text.Split([href], "/"),3), {"Agency","Resource","Version"})),
    #"Expanded Custom" = Table.ExpandRecordColumn(#"Added Custom", "Custom", {"Agency", "Resource", "Version"}, {"Agency", "Resource", "Version"}),
    #"Grouped Rows" = Table.Group(#"Expanded Custom", {"Agency"}, {{"Count", each _, type table [id=text, urn=text, href=text, value=text, lang=text, kind=text, Agency=text, Resource=text, Version=text]}}),
    #"Added Custom1" = Table.AddColumn(#"Grouped Rows", "Custom", each Table.Group([Count], {"Resource", "value"}, {{"Count", each _}})),
    #"Removed Columns" = Table.RemoveColumns(#"Added Custom1",{"Count"}),
    #"Added Custom2" = Table.AddColumn(#"Removed Columns", "Data", each ISTAC.CubosNivel2Transformar([Custom])),
    #"Removed Columns1" = Table.RemoveColumns(#"Added Custom2",{"Custom"}),
    #"Renamed Columns" = Table.RenameColumns(#"Removed Columns1",{{"Agency", "Key"}}),
    #"Duplicated Column" = Table.DuplicateColumn(#"Renamed Columns", "Key", "Name"),
    #"Duplicated Column1" = Table.DuplicateColumn(#"Duplicated Column", "Name", "ItemName"),
    #"Added Custom3" = Table.AddColumn(#"Duplicated Column1", "IsLeaf", each false),
    #"Added Custom4" = Table.AddColumn(#"Added Custom3", "ItemKind", each "Folder"),
    ToNavTable = Table.ToNavigationTable(  #"Added Custom4", {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
in
  ToNavTable;

ISTAC.CubosNivel2Transformar = (x as table) as table =>
let 
    #"Renamed Columns" = Table.RenameColumns(x,{{"Resource", "Key"}, {"value", "Name"}}),
    #"Added Custom" = Table.AddColumn(#"Renamed Columns", "ItemKind", each "Folder"),
    #"Added Custom1" = Table.AddColumn(#"Added Custom", "IsLeaf", each false),
    #"Duplicated Column" = Table.DuplicateColumn(#"Added Custom1", "Name", "ItemName"),
    #"Added Custom2" = Table.AddColumn(#"Duplicated Column", "Data", each ISTAC.CubosNivel3Transformar([Count])),
    ToNavTable =Table.ToNavigationTable(#"Added Custom2", {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf") 
in
    ToNavTable;

ISTAC.CubosNivel3Transformar = (x as table) as table =>
let
    #"Removed Other Columns" = Table.SelectColumns(x,{"href", "Version"}),
    #"Renamed Columns1" = Table.RenameColumns(#"Removed Other Columns",{{"Version", "Key"}}),
    #"Duplicated Column1" = Table.DuplicateColumn(#"Renamed Columns1", "Key", "Name"),
    #"Duplicated Column2" = Table.DuplicateColumn(#"Duplicated Column1", "Name", "ItemName"),
    #"Added Custom2" = Table.AddColumn(#"Duplicated Column2", "IsLeaf", each true),
    #"Added Custom3" = Table.AddColumn(#"Added Custom2", "ItemKind", each "Table"),
    #"Added Custom4" = Table.AddColumn(#"Added Custom3", "Data", each ISTAC.Dataset([href])),
    ToNavTable =Table.ToNavigationTable(#"Added Custom4", {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf") 
    in 
  ToNavTable;

ISTAC.Dataset = (url as text) as table =>
let
    x = Binary.Buffer( Web.Contents(url , [Headers=[Accept="application/json"]]) ),
    Source = Json.Document(x),
    data = Source[data],
    observation = Text.Split( data[observations], "|"),
    Custom2 = Table.FromRecords(  data[dimensions]?[dimension]? ),
    #"Expanded representations" = Table.ExpandRecordColumn(Custom2, "representations", {"representation"}, {"representation"}),
    #"Added Custom" = Table.AddColumn(#"Expanded representations", "Custom", each Table.FromRecords([representation], null, MissingField.UseNull)),
    #"Removed Columns" = Table.RemoveColumns(#"Added Custom",{"representation"}),
    Order = #"Removed Columns"[dimensionId],
    Custom3 = Table.Transpose( #"Removed Columns" ),
    #"Promoted Headers" = Table.PromoteHeaders(Custom3, [PromoteAllScalars=true]),
    TotalDimensions = List.Count( Order ),
    recursiveExpand = (x as table, y as number) => 
          let 
	     OriginalColumnNames = {"code", "index"},
             ColumnToExpand = Order{y-1},
             NewColumnNames = List.Transform(OriginalColumnNames, each ColumnToExpand &"."& _),
             Calculation =  Table.ExpandTableColumn(x,ColumnToExpand, OriginalColumnNames , NewColumnNames),
	     Check = if y = TotalDimensions then Calculation else @recursiveExpand (Calculation, y +1)
 	   in  
	     Check,
     Custom5= recursiveExpand (#"Promoted Headers" , 1),
      ColumnsToOrder = List.Transform( Order, each _ &".index"),
     ListOrder = List.Zip({ColumnsToOrder,List.Repeat({Order.Ascending}, List.Count(Order))}),
      #"Sorted Rows" = Table.Sort(Custom5,ListOrder),
    Custom6 = List.Select( Table.ColumnNames( #"Sorted Rows"), each Text.EndsWith(_, ".code")),
    Custom7 = Table.SelectColumns(#"Sorted Rows", Custom6),
     Custom8 = List.Zip( {Custom6, List.Transform( Custom6, each Text.Replace(_, ".code",""))} ),
    Custom9 = Custom7,
    #"Renamed Columns" = Table.RenameColumns(Custom9,Custom8),
    Custom10 = #"Renamed Columns",
    Custom11 = Table.FromColumns( Table.ToColumns(Custom10) & {observation}, Order & {"Value"}),
        #"Changed Type" = Table.TransformColumnTypes(Custom11, List.Zip( {Order, List.Repeat(  {type text}, List.Count(Order))}) ),
    #"Changed Type1" = Table.TransformColumnTypes(#"Changed Type",{{"Value", type number}}),
    #"Replaced Errors" = Table.ReplaceErrorValues(#"Changed Type1", {{"Value", null}}),
        #"Pivoted Column" = try  Table.Pivot(#"Replaced Errors", List.Distinct( #"Replaced Errors"[INDICADORES]), "INDICADORES", "Value")
otherwise Table.Pivot(#"Replaced Errors", List.Distinct( #"Replaced Errors"[MEDIDAS]), "MEDIDAS", "Value")
in
try #"Pivoted Column" otherwise #"Replaced Errors";

TransformBinary.Cubos = (url as text) as table =>
let
    x = Binary.Buffer( Web.Contents(url , [Headers=[Accept="application/json"]]) ),
    Source = Json.Document(x),
    data = Source[data],
    observation = Text.Split( data[observations], "|"),
    Custom2 = Table.FromRecords(  data[dimensions]?[dimension]? ),
    #"Expanded representations" = Table.ExpandRecordColumn(Custom2, "representations", {"representation"}, {"representation"}),
    #"Added Custom" = Table.AddColumn(#"Expanded representations", "Custom", each Table.FromRecords([representation], null, MissingField.UseNull)),
    #"Removed Columns" = Table.RemoveColumns(#"Added Custom",{"representation"}),
    Order = #"Removed Columns"[dimensionId],
    Custom3 = Table.Transpose( #"Removed Columns" ),
    #"Promoted Headers" = Table.PromoteHeaders(Custom3, [PromoteAllScalars=true]),
    TotalDimensions = List.Count( Order ),
    recursiveExpand = (x as table, y as number) => 
          let 
	     OriginalColumnNames = {"code", "index"},
             ColumnToExpand = Order{y-1},
             NewColumnNames = List.Transform(OriginalColumnNames, each ColumnToExpand &"."& _),
             Calculation =  Table.ExpandTableColumn(x,ColumnToExpand, OriginalColumnNames , NewColumnNames),
	     Check = if y = TotalDimensions then Calculation else @recursiveExpand (Calculation, y +1)
 	   in  
	     Check,
     Custom5= recursiveExpand (#"Promoted Headers" , 1),
      ColumnsToOrder = List.Transform( Order, each _ &".index"),
     ListOrder = List.Zip({ColumnsToOrder,List.Repeat({Order.Ascending}, List.Count(Order))}),
      #"Sorted Rows" = Table.Sort(Custom5,ListOrder),
    Custom6 = List.Select( Table.ColumnNames( #"Sorted Rows"), each Text.EndsWith(_, ".code")),
    Custom7 = Table.SelectColumns(#"Sorted Rows", Custom6),
     Custom8 = List.Zip( {Custom6, List.Transform( Custom6, each Text.Replace(_, ".code",""))} ),
    Custom9 = Custom7,
    #"Renamed Columns" = Table.RenameColumns(Custom9,Custom8),
    Custom10 = #"Renamed Columns",
    Custom11 = Table.FromColumns( Table.ToColumns(Custom10) & {observation}, Order & {"Value"}),
        #"Changed Type" = Table.TransformColumnTypes(Custom11, List.Zip( {Order, List.Repeat(  {type text}, List.Count(Order))}) ),
    #"Changed Type1" = Table.TransformColumnTypes(#"Changed Type",{{"Value", type number}}),
    #"Replaced Errors" = Table.ReplaceErrorValues(#"Changed Type1", {{"Value", null}}),
        #"Pivoted Column" = Table.Pivot(#"Replaced Errors", List.Distinct(#"Replaced Errors"[INDICADORES]), "INDICADORES", "Value")
in
#"Pivoted Column";

TransformBinary.Indicadores= (url as text) as table =>
let
x= Binary.Buffer( Web.Contents(url & "/data", [Headers=[Accept="application/json"]]) ),
JSON = Json.Document(x),
    Custom2 = JSON,
    Order = Custom2[format],
    Custom3 = Record.ToTable( Custom2[dimension] ),
    #"Expanded Value" = Table.ExpandRecordColumn(Custom3, "Value", {"representation"}, {"representation"}),
    #"Expanded representation" = Table.ExpandRecordColumn(#"Expanded Value", "representation", {"index"}, {"index"}),
    #"Added Custom1" = Table.AddColumn(#"Expanded representation", "MyTable", each Record.ToTable([index])),
    #"Removed Columns" = Table.RemoveColumns(#"Added Custom1",{"index"}),
    #"Transposed Table" = Table.Transpose(#"Removed Columns"),
    #"Promoted Headers" = Table.PromoteHeaders(#"Transposed Table", [PromoteAllScalars=true]),
    Custom4 = #"Promoted Headers",
    TotalDimensions = List.Count( Order ),
    recursiveExpand = (x as table, y as number) => 
          let 
	     OriginalColumnNames = {"Name", "Value"},
             ColumnToExpand = Order{y-1},
             NewColumnNames = List.Transform(OriginalColumnNames, each ColumnToExpand &"."& _),
             Calculation =  Table.ExpandTableColumn(x,ColumnToExpand, OriginalColumnNames , NewColumnNames),
	     Check = if y = TotalDimensions then Calculation else @recursiveExpand (Calculation, y +1)
 	   in  
	     Check,
     Custom5= recursiveExpand (Custom4, 1),
     ColumnsToOrder = List.Transform( Order, each _ &".Value"),
     ListOrder = List.Zip({ColumnsToOrder,List.Repeat({Order.Ascending}, List.Count(Order))}),
    #"Sorted Rows" = Table.Sort(Custom5,ListOrder),
    Custom6 = List.Select( Table.ColumnNames( #"Sorted Rows"), each Text.EndsWith(_, ".Name")),
    Custom7 = Table.SelectColumns(#"Sorted Rows", Custom6),
    Custom8 = List.Zip( {Custom6, List.Transform( Custom6, each Text.Replace(_, ".Name",""))} ),
    Custom9 = Custom7,
    #"Renamed Columns" = Table.RenameColumns(Custom9,Custom8),
    Custom10 = #"Renamed Columns",
    observation = JSON[observation],
    Custom11 = Table.FromColumns( Table.ToColumns(Custom10) & {observation}, Order & {"Value"}),
    #"Changed Type" = Table.TransformColumnTypes(Custom11, List.Zip( {Order, List.Repeat(  {type text}, List.Count(Order))}) ),
    #"Changed Type1" = Table.TransformColumnTypes(#"Changed Type",{{"Value", type number}}),
    #"Replaced Errors" = Table.ReplaceErrorValues(#"Changed Type1", {{"Value", null}}),
    #"Pivoted Column" = Table.Pivot(#"Replaced Errors", List.Distinct(#"Replaced Errors"[MEASURE]), "MEASURE", "Value")
in
    #"Pivoted Column";

ISTAC.IndicatorGeographicGranularities= () as table =>
let
    Source = Json.Document(Web.Contents("https://www3.gobiernodecanarias.org/istac/api/indicators/v1.0/geographicGranularities")),
    items = Table.FromRecords(Source[items], null, MissingField.UseNull),
    #"Expanded title" = Table.ExpandRecordColumn(items, "title", {"en", "es", "__default__"}, {"en", "es", "__default__"}),
    #"Changed Type" = Table.TransformColumnTypes(#"Expanded title",{{"__default__", type text}, {"es", type text}, {"en", type text}, {"code", type text}}),
    #"Added Custom" = Table.AddColumn(#"Changed Type", "Value", each Table.FromRecords(  Json.Document(Web.Contents("https://www3.gobiernodecanarias.org/istac/api/indicators/v1.0/geographicalValues?geographicalGranularityCode="&[code]))[items], null, MissingField.UseNull)),
    #"Expanded Value" = Table.ExpandTableColumn(#"Added Custom", "Value", {"code", "title", "granularityCode", "latitude", "longitude"}, {"Value.code", "Value.title", "Value.granularityCode", "Value.latitude", "Value.longitude"}),
    #"Changed Type1" = Table.TransformColumnTypes(#"Expanded Value",{{"Value.longitude", type number}, {"Value.latitude", type number}, {"Value.granularityCode", type text}, {"Value.code", type text}})
in
    #"Changed Type1";

ISTAC.IndicatorSubjects = () as table =>
    let
    Source = Json.Document(Web.Contents("https://www3.gobiernodecanarias.org/istac/api/indicators/v1.0/subjects"))[items],
    Custom1 = Table.FromRecords( Source )
in
    Custom1;

ISTAC.IndicatorTimeSeries = () as table =>
    let
    Source = Json.Document(Web.Contents("https://www3.gobiernodecanarias.org/istac/api/indicators/v1.0/timeGranularities"))[items],
    Custom1 = Table.FromRecords( Source )
in
    Custom1;

ISTAC.SystemIndicators = () =>
    let
    Source = ISTAC.SystemIndicatorPagination("https://www.gobiernodecanarias.org/istac/api/indicators/v1.0/indicatorsSystems", 1000),
    #"Added Custom" = Table.AddColumn(Source, "Custom", each ISTAC.SystemIndicatorPagination([selfLink]&"/indicatorsInstances", 1000)),
    #"Expanded title" = Table.ExpandRecordColumn(#"Added Custom", "title", {"__default__"}, {"title.__default__"}),
    #"Renamed Columns" = Table.RenameColumns(#"Expanded title",{{"id", "Key"}, {"title.__default__", "Name"}}),
    #"Removed Other Columns" = Table.SelectColumns(#"Renamed Columns",{"Key", "Name", "Custom"}),
    #"Added Custom1" = Table.AddColumn(#"Removed Other Columns", "ItemKind", each "Folder"),
    #"Added Custom2" = Table.AddColumn(#"Added Custom1", "IsLeaf", each false),
    #"Duplicated Column" = Table.DuplicateColumn(#"Added Custom2", "Name", "ItemName"),
    #"Added Custom3" = Table.AddColumn(#"Duplicated Column", "Custom.1", each Table.AddColumn([Custom], "Data", each  TransformBinary.Indicadores([selfLink]) )),
    #"Removed Columns" = Table.RemoveColumns(#"Added Custom3",{"Custom"}),
    #"Added Custom4" = Table.AddColumn(#"Removed Columns", "Data", each ISTAC.SystemIndicatorSubLevel([Custom.1])),
    #"Removed Columns1" = Table.RemoveColumns(#"Added Custom4",{"Custom.1"}),
    ReorderColumns= Table.ReorderColumns(#"Removed Columns1",{"Key", "Name", "ItemKind", "Data", "ItemName", "IsLeaf"}),
    ToNavTable = Table.ToNavigationTable( ReorderColumns , {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
in
    ToNavTable ;

ISTAC.SystemIndicatorSubLevel = (x as table) as table =>
let
 #"Expanded title1" = Table.ExpandRecordColumn(x, "title", {"es", "__default__"}, {"title.es", "title.__default__"}),
    #"Renamed Columns1" = Table.RenameColumns(#"Expanded title1",{{"title.__default__", "Name"}, {"id", "Key"}}),
    #"Duplicated Column1" = Table.DuplicateColumn(#"Renamed Columns1", "Name", "ItemName"),
    #"Added Custom4" = Table.AddColumn(#"Duplicated Column1", "IsLeaf", each true),
    #"Added Custom5" = Table.AddColumn(#"Added Custom4", "ItemKind", each "Table"),
    #"Removed Other Columns1" = Table.SelectColumns(#"Added Custom5",{"Key", "Name", "ItemName", "IsLeaf", "Data", "ItemKind"}),
     ReorderColumns= Table.ReorderColumns(#"Removed Other Columns1",{"Key", "Name", "ItemKind", "Data", "ItemName", "IsLeaf"}),
      ToNavTable = Table.ToNavigationTable( ReorderColumns, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
in
ToNavTable;

ISTAC.SystemIndicatorPagination = (url as text, myLimit as number) as table => 
let
    Source = List.Generate( ()=>

[Call = Json.Document(Web.Contents(url, 
      [Query= 
       [limit=Text.From(Limit), offset=Text.From(Offset)], 
        Headers=[Accept="application/json"]])), 
        Offset=0, 
        Limit=myLimit],    
        each List.NonNullCount( Record.Field( [Call], "items" ) ) > 0, 
      each [Offset= [Offset]+[Limit], Limit = [Limit], Call = Json.Document(Web.Contents(url, [Query= [limit=Text.From(Limit), offset=Text.From(Offset)], Headers=[Accept="application/json"]]))],
each Table.FromRecords( Record.Field( [Call], "items" ), null, MissingField.UseNull)),
    Custom1 = Table.Combine(Source)
in
    Custom1;

ISTAC = [
     TestConnection = (dataSourcePath) => { "ISTAC.Contents" },
    Authentication = [
        Implicit = []
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

// Data Source UI publishing description
ISTAC.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = ISTAC.Icons,
    SourceTypeImage = ISTAC.Icons
];

ISTAC.Icons = [
    Icon16 = { Extension.Contents("ISTAC16.png"), Extension.Contents("ISTAC20.png"), Extension.Contents("ISTAC24.png"), Extension.Contents("ISTAC32.png") },
    Icon32 = { Extension.Contents("ISTAC32.png"), Extension.Contents("ISTAC40.png"), Extension.Contents("ISTAC48.png"), Extension.Contents("ISTAC64.png") }
];


Table.ToNavigationTable = (
    table as table,
    keyColumns as list,
    nameColumn as text,
    dataColumn as text,
    itemKindColumn as text,
    itemNameColumn as text,
    isLeafColumn as text
) as table =>
    let
        tableType = Value.Type(table),
        newTableType = (try Type.AddTableKey(tableType, keyColumns, true) otherwise tableType )  meta 
        [
            NavigationTable.NameColumn = nameColumn, 
            NavigationTable.DataColumn = dataColumn,
            NavigationTable.ItemKindColumn = itemKindColumn, 
            Preview.DelayColumn = itemNameColumn, 
            NavigationTable.IsLeafColumn = isLeafColumn
        ],
        navigationTable = Value.ReplaceType(table, newTableType)
    in
        navigationTable;