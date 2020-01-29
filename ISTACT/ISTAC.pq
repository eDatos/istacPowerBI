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
            {"Cubos",      "Cubos",  ISTAC.SistemasEstadisticos (), "Folder",    "Cubos",    false},
            {"Clasificaciones",      "Clasificaciones",  ISTAC.VariableFamilies() , "Folder",    "Clasificaciones",    false}
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
            {"Geográficos",      "Geográficos",  ISTAC.IndicatorGeographicGranularities() , "Table",    "Geográfico",    true}
            }),
              NavTable = Table.ToNavigationTable(objects, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf") 
              in 
                  NavTable;

ISTAC.Indicadores = () as table =>
 let
     Source = ISTAC.AlternatePagination("https://www3.gobiernodecanarias.org/istac/api/indicators/v1.0/indicators?limit=1000", "items"),
    #"Expanded title" = Table.ExpandRecordColumn(Source, "title", {"es", "en", "__default__"}, {"title.es", "title.en", "title.__default__"}),
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
           #"Renamed Columns" = Table.RenameColumns(x,{{"id", "Key"}, {"title.__default__", "Name"}}),
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

ISTAC.SistemasEstadisticos = () =>
    let
    Source = ISTAC.AlternatePagination("https://www3.gobiernodecanarias.org/istac/api/operations/v1.0/operations?limit=1000", "operation"),
    #"Expanded name" = Table.ExpandRecordColumn(Source, "name", {"text"}, {"name.text"}),
    #"Expanded name.text" = Table.ExpandListColumn(#"Expanded name", "name.text"),
    #"Expanded name.text1" = Table.ExpandRecordColumn(#"Expanded name.text", "name.text", {"value", "lang"}, {"name.text.value", "name.text.lang"}),
    #"Filtered Rows" = Table.SelectRows(#"Expanded name.text1", each ([name.text.lang] = "es")),
    #"Removed Columns" = Table.RemoveColumns(#"Filtered Rows",{"selfLink"}),
    #"Added Custom" = Table.AddColumn(#"Removed Columns", "Data", each ISTAC.Cubos( "https://www3.gobiernodecanarias.org/istac/api/statistical-resources/v1.0/datasets?lang=es&limit=1000&query=STATISTICAL_OPERATION_URN EQ '" & Text.From([urn]) & "'")),
    #"Removed Errors" = Table.RemoveRowsWithErrors(#"Added Custom", {"Data"}),
    #"Removed Columns1" = Table.RemoveColumns(#"Removed Errors",{"urn", "name.text.lang", "kind"}),
    #"Renamed Columns" = Table.RenameColumns(#"Removed Columns1",{{"id", "Key"}}),
    #"Added Custom1" = Table.AddColumn(#"Renamed Columns", "Name", each "("&[Key]&") "&[name.text.value]),
    #"Renamed Columns1" = Table.RenameColumns(#"Added Custom1",{{"name.text.value", "ItemName"}}),
    #"Added Custom2" = Table.AddColumn(#"Renamed Columns1", "ItemKind", each "Folder"),
    #"Added Custom3" = Table.AddColumn(#"Added Custom2", "IsLeaf", each false),
 ToNavTable = Table.ToNavigationTable(   #"Added Custom3" , {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
in
  ToNavTable;


ISTAC.Cubos = (url as text)=>
   let
    Source = ISTAC.AlternatePagination(url,"dataset"),
    #"Expanded name" = Table.ExpandRecordColumn(Source, "name", {"text"}, {"text"}),
    #"Expanded text" = Table.ExpandListColumn(#"Expanded name", "text"),
    #"Expanded text1" = Table.ExpandRecordColumn(#"Expanded text", "text", {"value", "lang"}, {"value", "lang"}),
    #"Expanded selfLink" = Table.ExpandRecordColumn(#"Expanded text1", "selfLink", {"href"}, {"href"}),
    #"Added Custom" = Table.AddColumn(#"Expanded selfLink", "Custom", each Record.FromList( List.LastN( Text.Split([href], "/"),3), {"Agency","Resource","Version"})),
    #"Expanded Custom" = Table.ExpandRecordColumn(#"Added Custom", "Custom", {"Agency", "Resource", "Version"}, {"Agency", "Resource", "Version"}),
    #"Grouped Rows" = Table.Group(#"Expanded Custom", {"Agency", "value", "lang", "Resource"}, {{"Count", each _, type table [id=text, urn=text, href=text, value=text, lang=text, kind=text, Agency=text, Resource=text, Version=text]}}),
    #"Removed Columns" = Table.RemoveColumns(#"Grouped Rows",{"Count", "lang"}),
      #"Changed Type" = Table.TransformColumnTypes(#"Removed Columns",{{"Resource", type text}}),
    #"Added Custom3" = Table.AddColumn(#"Changed Type", "Data", each ISTAC.Dataset("https://www3.gobiernodecanarias.org/istac/api/statistical-resources/v1.0/datasets/ISTAC/"&Text.From([Resource])&"/~latest.json")),
    RemoveAgency = Table.RemoveColumns(#"Added Custom3", {"Agency"} ),
    RenameColumns = Table.RenameColumns(RemoveAgency,{{"Resource", "Key"}, {"value", "ItemName"}}),
    AddItemKind = Table.AddColumn(RenameColumns, "ItemKind", each "Table"),
    AddIsLeaf = Table.AddColumn(AddItemKind, "IsLeaf", each true),
    AddName =  Table.AddColumn(AddIsLeaf, "Name", each "("& [Key]  &") "& [ItemName]),
    ToNavTable = Table.ToNavigationTable(  AddName , {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
in
  ToNavTable;

ISTAC.Dataset = (url as text) as table =>
let
  x = Binary.Buffer( Web.Contents(url , [Headers=[Accept="application/json"]]) ),
    Source = Json.Document(x),
      Metadata = CubeMetadata( Source),
    ValuesColumn = CubeValuesAsTable(Source),
    DimensionColumns = CubeDimensions(Source, Metadata),
    #"Merged Queries" = Table.NestedJoin(DimensionColumns, {"Index"}, ValuesColumn, {"Index"}, "ValuesAsTable", JoinKind.LeftOuter),
    #"Removed Columns" = Table.RemoveColumns(#"Merged Queries",{"Index"}),
    #"Expanded ValuesAsTable" = Table.ExpandTableColumn(#"Removed Columns", "ValuesAsTable", {"Values"}, {"Values"}),
    #"Changed Type" = Table.TransformColumnTypes(#"Expanded ValuesAsTable",{{"Values", type number}}, "en-us")
in
    #"Changed Type";

CubeValuesAsTable = (x as record) as table =>
let
    ValuesList = x[data],
    Values= Text.Split( ValuesList [observations], "|"), 
    Source = Table.FromList( Values, Splitter.SplitByNothing()),
    Custom1 = Table.AddIndexColumn(  Source, "Index", 0),
    #"Renamed Columns" = Table.RenameColumns(Custom1,{{"Column1", "Values"}})
in
    #"Renamed Columns";

 CubeMetadata = (x as record) as table => 
let
    metadata = x[metadata],
    dimensions = metadata[dimensions],
    dimension = dimensions[dimension],
    Custom1 = Table.FromRecords( dimension ),
    #"Expanded dimensionValues" = Table.ExpandRecordColumn(Custom1, "dimensionValues", {"value"}, {"value"}),
    #"Expanded value" = Table.ExpandListColumn(#"Expanded dimensionValues", "value"),
    #"Removed Columns" = Table.RemoveColumns(#"Expanded value",{"name"}),
    #"Expanded value1" = Table.ExpandRecordColumn(#"Removed Columns", "value", {"id", "name"}, {"id.1", "name"}),
    #"Expanded name" = Table.ExpandRecordColumn(#"Expanded value1", "name", {"text"}, {"text"}),
    #"Expanded text" = Table.ExpandListColumn(#"Expanded name", "text"),
    #"Expanded text1" = Table.ExpandRecordColumn(#"Expanded text", "text", {"value", "lang"}, {"value", "lang"}),
    #"Filtered Rows" = Table.SelectRows(#"Expanded text1", each ([lang] = "es")),
    #"Removed Columns1" = Table.RemoveColumns(#"Filtered Rows",{"lang"}),
    Custom2 = Table.Buffer( #"Removed Columns1" ),
    #"Renamed Columns" = Table.RenameColumns(Custom2,{{"id.1", "code"}})
in
    #"Renamed Columns";

CubeDimensions = (x as record, y as table) as table =>
let
    Source = x[data],
    dimensions = Source[dimensions],
    dimension = Table.FromRecords( dimensions[dimension]),
    #"Expanded representations" = Table.ExpandRecordColumn(dimension, "representations", {"representation"}, {"representations.representation"}),
    Custom1 = Table.TransformColumns( #"Expanded representations", {{"representations.representation", Table.FromRecords }}),
    #"Transposed Table" = Table.Transpose(Custom1),
    #"Promoted Headers" = Table.PromoteHeaders(#"Transposed Table", [PromoteAllScalars=true]),
    #"Expanded TERRITORIO" = List.Accumulate( dimension[dimensionId] , 
 #"Promoted Headers",
(state, column) => Table.ExpandTableColumn(state, column, {"code", "index"}, List.Transform({"code", "index"}, each Text.Combine({column,".", _ } ) )   )),
    Custom2 = List.Accumulate( dimension[dimensionId], 
 #"Expanded TERRITORIO",
(state, column) => Table.NestedJoin(state, {column&".code"}, Table.SelectRows( y, each [id]= column), {"code"}, column&".value" )),
    Custom3 = List.Accumulate( dimension[dimensionId] , 
 Custom2,
(state, column) => Table.ExpandTableColumn(state, column&".value", {"value"}, {column&".label"}   )),
    Order = List.Zip({List.Transform(dimension[dimensionId], each _&".index"),  List.Repeat( {Order.Ascending }, List.Count(dimension[dimensionId]))}),
    Output = Table.Sort(Custom3, Order),
    #"Added Index" = Table.AddIndexColumn(Output, "Index", 0, 1),
    Custom4 = Table.RemoveColumns( #"Added Index", List.Transform(dimension[dimensionId], each _&".index" ))
in
    Custom4;

TransformBinary.Indicadores= (url as text) as table =>
let
x= Binary.Buffer( Web.Contents(url & "/data", [Headers=[Accept="application/json"]]) ),
JSON = Json.Document(x),
    Order = JSON[format],
    Custom3 = Record.ToTable( JSON[dimension] ),
    #"Expanded Value" = Table.ExpandRecordColumn(Custom3, "Value", {"representation"}, {"representation"}),
    #"Expanded representation" = Table.ExpandRecordColumn(#"Expanded Value", "representation", {"index"}, {"index"}),
    #"Added Custom1" = Table.AddColumn(#"Expanded representation", "MyTable", each Record.ToTable([index])),
    #"Removed Columns" = Table.RemoveColumns(#"Added Custom1",{"index"}),
    #"Transposed Table" = Table.Transpose(#"Removed Columns"),
    #"Promoted Headers" = Table.PromoteHeaders(#"Transposed Table", [PromoteAllScalars=true]),
     Custom5= List.Accumulate( Order, 
#"Promoted Headers",
(state, column) => Table.ExpandTableColumn(state, column, {"Name", "Value"}, List.Transform({"Name", "Value"}, each Text.Combine({column,".", _ } ) )   )),
     ColumnsToOrder = List.Transform( Order, each _ &".Value"),
     ListOrder = List.Zip({ColumnsToOrder,List.Repeat({Order.Ascending}, List.Count(Order))}),
    #"Sorted Rows" = Table.Sort(Custom5,ListOrder),
    Custom6 = List.Select( Table.ColumnNames( #"Sorted Rows"), each Text.EndsWith(_, ".Name")),
    Custom7 = Table.SelectColumns(#"Sorted Rows", Custom6),
    Custom8 = List.Zip( {Custom6, List.Transform( Custom6, each Text.Replace(_, ".Name",""))} ),
    Custom9 = Custom7,
    #"Renamed Columns" = Table.RenameColumns(Custom9,Custom8),
    Custom10 = Table.AddIndexColumn( #"Renamed Columns", "Index", 0, 1),
    observation = Table.AddIndexColumn( Table.FromList( JSON[observation]), "Index", 0,1),
    Custom11 = Table.NestedJoin( Custom10, {"Index"}, observation, {"Index"}, "New"),
    #"Expanded New" = Table.ExpandTableColumn(Custom11, "New", {"Column1"}, {"Column1"}),
    #"Removed Columns1" = Table.RemoveColumns(#"Expanded New",{"Index"}),
    #"Renamed Columns1" = Table.RenameColumns(#"Removed Columns1",{{"Column1", "VALUE"}}),
    #"Changed Type with Locale" = Table.TransformColumnTypes(#"Renamed Columns1", {{"VALUE", type number}}, "en-US"),
    #"Changed Type2" = Table.TransformColumnTypes(#"Changed Type with Locale",{{"MEASURE", type text}, {"TIME", type text}, {"GEOGRAPHICAL", type text}}),
    #"Replaced Errors" = Table.ReplaceErrorValues(#"Changed Type2", {{"VALUE", null}}),
    #"Replaced Value" = Table.ReplaceValue(#"Replaced Errors","ABSOLUTE","Dato",Replacer.ReplaceText,{"MEASURE"}),
    #"Replaced Value1" = Table.ReplaceValue(#"Replaced Value","ANNUAL_PERCENTAGE_RATE","Tasa variación anual",Replacer.ReplaceText,{"MEASURE"}),
    #"Replaced Value2" = Table.ReplaceValue(#"Replaced Value1","INTERPERIOD_PERCENTAGE_RATE","Tasa variación interperiódica",Replacer.ReplaceText,{"MEASURE"}),
    #"Replaced Value3" = Table.ReplaceValue(#"Replaced Value2","ANNUAL_PUNTUAL_RATE","Variación anual",Replacer.ReplaceText,{"MEASURE"}),
    #"Replaced Value4" = Table.ReplaceValue(#"Replaced Value3","INTERPERIOD_PUNTUAL_RATE","Variación interperiódica",Replacer.ReplaceText,{"MEASURE"})
in
    #"Replaced Value4";

ISTAC.IndicatorGeographicGranularities= () as table =>
let
    Source = Json.Document(Web.Contents("https://www3.gobiernodecanarias.org/istac/api/indicators/v1.0/geographicGranularities")),
    items = Table.FromRecords(Source[items], null, MissingField.UseNull),
    #"Expanded title" = Table.ExpandRecordColumn(items, "title", {"en", "es", "__default__"}, {"en", "es", "__default__"}),
    #"Changed Type" = Table.TransformColumnTypes(#"Expanded title",{{"__default__", type text}, {"es", type text}, {"en", type text}, {"code", type text}}),
    #"Added Custom" = Table.AddColumn(#"Changed Type", "Value", each Table.FromRecords(  Json.Document(Web.Contents("https://www3.gobiernodecanarias.org/istac/api/indicators/v1.0/geographicalValues?geographicalGranularityCode="&[code]))[items], null, MissingField.UseNull)),
    #"Expanded Value" = Table.ExpandTableColumn(#"Added Custom", "Value", {"code", "title", "granularityCode", "latitude", "longitude"}, {"Value.code", "Value.title", "Value.granularityCode", "Value.latitude", "Value.longitude"}),
    #"Changed Type1" = Table.TransformColumnTypes(#"Expanded Value",{{"Value.longitude", type number}, {"Value.latitude", type number}, {"Value.granularityCode", type text}, {"Value.code", type text}},  "en-US")
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

ISTAC.VariableFamilies = () as table =>
  let
   Source = ISTAC.AlternatePagination("https://www3.gobiernodecanarias.org/istac/api/structural-resources/v1.0/variablefamilies?limit=25", "variableFamily"),
    #"Expanded selfLink" = Table.ExpandRecordColumn(Source, "selfLink", {"kind", "href"}, {"kind.1", "href"}),
    #"Expanded name" = Table.ExpandRecordColumn(#"Expanded selfLink", "name", {"text"}, {"text"}),
    #"Expanded text" = Table.ExpandListColumn(#"Expanded name", "text"),
    #"Expanded text1" = Table.ExpandRecordColumn(#"Expanded text", "text", {"value", "lang"}, {"value", "lang"}),
    #"Filtered Rows" = Table.SelectRows(#"Expanded text1", each [lang] = "es"),
    #"Added Custom" = Table.AddColumn(#"Filtered Rows", "Custom", each try ISTAC.AlternatePagination([href]&"/variables?limit=2", "variable") otherwise error Error.Record("Sin información", "Esta variable no contiene clasificaciones", "Error")),
    #"Renamed Columns" = Table.RenameColumns(#"Added Custom",{{"id", "Key"}, {"value", "Name"}}),
    #"Duplicated Column" = Table.DuplicateColumn(#"Renamed Columns", "Name", "ItemName"),
    #"Added Custom1" = Table.AddColumn(#"Duplicated Column", "IsLeaf", each false),
    #"Added Custom2" = Table.AddColumn(#"Added Custom1", "ItemKind", each "Folder"),
    #"Removed Other Columns" = Table.SelectColumns(#"Added Custom2",{"IsLeaf", "ItemKind", "ItemName", "Custom", "Name", "Key"}),
    #"Added Custom3" = Table.AddColumn(#"Removed Other Columns", "Data", each ISTAC.VariableFamiliesLevel2 ([Custom])),
    #"Removed Columns" = Table.RemoveColumns(#"Added Custom3",{"Custom"}),
       RemoveLabels = Table.ReplaceValue( #"Removed Columns" ,"Familia de Variables ","",Replacer.ReplaceText,{"Name"}),
     ToNavTable = Table.ToNavigationTable( RemoveLabels, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
in
try ToNavTable otherwise error Error.Record("Sin información", "Esta variable no contiene clasificaciones", "Error");

ISTAC.VariableFamiliesLevel2 = (x as table) => 
let
   #"Expanded name" = Table.ExpandRecordColumn(x, "name", {"text"}, {"text"}),
    #"Expanded text" = Table.ExpandListColumn(#"Expanded name", "text"),
    #"Expanded text1" = Table.ExpandRecordColumn(#"Expanded text", "text", {"value", "lang"}, {"value", "lang"}),
    #"Expanded selfLink" = Table.ExpandRecordColumn(#"Expanded text1", "selfLink", {"kind", "href"}, {"kind.1", "href"}),
    #"Renamed Columns" = Table.RenameColumns(#"Expanded selfLink",{{"value", "Name"}, {"id", "Key"}}),
    #"Duplicated Column" = Table.DuplicateColumn(#"Renamed Columns", "Name", "ItemName"),
    #"Added Custom1" = Table.AddColumn(#"Duplicated Column", "IsLeaf", each false),
    AddItemKind = Table.AddColumn( #"Added Custom1", "ItemKind", each "Folder"),
    #"Added Custom" = Table.AddColumn(AddItemKind, "Custom", each try ISTAC.AlternatePagination("https://www3.gobiernodecanarias.org/istac/api/structural-resources/v1.0/codelists?query=VARIABLE_URN%20EQ%20%22urn%3Asiemac%3Aorg.siemac.metamac.infomodel.structuralresources.Variable%3D" & [Key] & "%22 ", "codelist") otherwise error Error.Record("Sin información", "Esta variable no contiene clasificaciones", "Error")),
    #"Added Custom2" = Table.AddColumn(#"Added Custom", "Data", each ISTAC.VariableFamiliesLevel3([Custom])),
    #"Removed Other Columns" = Table.SelectColumns(#"Added Custom2",{"Key", "Name", "ItemName", "IsLeaf", "ItemKind", "Data"}),
   RemoveLabels = Table.ReplaceValue(  #"Removed Other Columns" ,"Variable ","",Replacer.ReplaceText,{"Name"}),
     ToNavTable = Table.ToNavigationTable(  RemoveLabels , {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
in
try ToNavTable otherwise error Error.Record("Sin información", "Esta variable no contiene clasificaciones", "Error");

ISTAC.VariableFamiliesLevel3 = (x as table) =>
   let
    #"Expanded name" = Table.ExpandRecordColumn(x, "name", {"text"}, {"text"}),
    #"Expanded text" = Table.ExpandListColumn(#"Expanded name", "text"),
    #"Expanded text1" = Table.ExpandRecordColumn(#"Expanded text", "text", {"value", "lang"}, {"value", "lang"}),
    #"Filtered Rows" = Table.SelectRows(#"Expanded text1", each ([lang] = "es")),
    #"Expanded selfLink" = Table.ExpandRecordColumn(#"Filtered Rows", "selfLink", {"kind", "href"}, {"kind.1", "href"}),
    #"Added Custom" = Table.AddColumn(#"Expanded selfLink", "Data", each ISTAC.VariableFamiliesLevel4( ISTAC.AlternatePagination([href] &"/codes.json?fields=+variableElement", "code"  ) )),
    #"Removed Other Columns" = Table.SelectColumns(#"Added Custom",{"urn", "value", "Data"}),
    #"Renamed Columns" = Table.RenameColumns(#"Removed Other Columns",{{"value", "Name"}, {"urn", "Key"}}),
    #"Duplicated Column" = Table.DuplicateColumn(#"Renamed Columns", "Name", "ItemName"),
    #"Added Custom1" = Table.AddColumn(#"Duplicated Column", "IsLeaf", each true),
    AddItemKind = Table.AddColumn( #"Added Custom1", "ItemKind", each "Table"),
    ToNavTable = Table.ToNavigationTable( AddItemKind, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
in
try ToNavTable otherwise error Error.Record("Sin información", "Esta variable no contiene clasificaciones", "Error") ;


ISTAC.VariableFamiliesLevel4 = (x as table) =>
    let
            #"Se expandió name" = Table.ExpandRecordColumn(x, "name", {"text"}, {"name.text"}),
    #"Se expandió name.text" = Table.ExpandListColumn(#"Se expandió name", "name.text"),
    #"Se expandió name.text1" = Table.ExpandRecordColumn(#"Se expandió name.text", "name.text", {"value", "lang"}, {"name.text.value", "name.text.lang"}),
    #"Changed Type" = type table [id =text, urn = text, selfLink = record, kind= text, name.text.value=  text,name.text.lang = text],
    Custom1 = Value.ReplaceType(#"Se expandió name.text1", #"Changed Type")
in
   try Custom1 otherwise error Error.Record("Sin información", "Esta variable no contiene clasificaciones", "Error");

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
            Preview.DelayColumn = dataColumn, 
            NavigationTable.IsLeafColumn = isLeafColumn
        ],
        navigationTable = Value.ReplaceType(table, newTableType)
    in
        navigationTable;