[Version = "1.0.0"]
section ISTAC;

[DataSource.Kind="ISTAC", Publish="ISTAC.Publish"]
shared ISTAC.Contents =  Value.ReplaceType(Navigation, NavigationType);

// Metadatos para la función ISTAC.Contents
NavigationType = type function () as table meta [                  
        Documentation.Name = "ISTAC – Datos y metadatos",
        Documentation.LongDescription = "Devuelve una tabla con datos clave de la API de datos ISTAC",
        Documentation.Examples = {[
            Description = "Devuelve una tabla con datos clave de la API de datos ISTAC",
            Code = "ISTAC.Contents () ",
            Result = "Una tabla con datos clave de la API de datos ISTAC"
        ]}
    ];

// Nivel superior de la tabla de navegación del conector
 Navigation = () =>
    let
        objects = #table(
            {"Name",       "Key",        "Data",                           "ItemKind", "ItemName", "IsLeaf"},{
            {"Indicadores",      "indicators",  ISTAC.IndicatorNavTable() , "Folder",    "Indicator",    false}, 
            {"Cubos",      "Cubos",  ISTAC.CubosNavTable (), "Folder",    "Cubos",    false},
            {"Clasificaciones",      "Clasificaciones",  ISTAC.ClasificacionesNavTable(), "Folder",    "Clasificaciones",    false},
            {"ISTAC.base", "ISTAC.base", ISTAC.base, "Function", "ISTAC.base", true}
            }),
        NavTable = Table.ToNavigationTable(objects, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf") 
    in
        NavTable;

// Navegación específica para Indicadores
ISTAC.IndicatorNavTable = ()=> 
      let
        objects = #table(
            {"Name",       "Key",        "Data",                           "ItemKind", "ItemName", "IsLeaf"},{
            {"Por temas",      "indicators",  ISTAC.Indicadores() , "Folder",    "Por temas",    false},
            {"Por sistemas de indicadores", "SystemIndicators", ISTAC.SystemIndicators(), "Folder", "Por sistemas de indicadores", false},
            {"fx URL del indicador / instancia de indicador", "GETIndicadores", ISTAC.GETIndicadores, "Function", "fx URL del indicador / instancia de indicador", true}
           }),
        NavTable = Table.ToNavigationTable(objects, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf") 
    in
        NavTable;

// Navegación específica para Cubos
ISTAC.CubosNavTable = ()=> 
      let
        objects = #table(
            {"Name",       "Key",        "Data",                           "ItemKind", "ItemName", "IsLeaf"},{
            {"Por operaciones estadísticas",      "Cubos",  ISTAC.SistemasEstadisticos (), "Folder",    "Por operaciones estadísticas",    false},
            {"fx URL del cubo / consulta de datos", "GETClasificaciones", ISTAC.GETDataset, "Function", "fx URL del cubo / consulta de datos", true}
           }),
        NavTable = Table.ToNavigationTable(objects, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf") 
    in
        NavTable;

// Navegación específica para Clasificaciones
ISTAC.ClasificacionesNavTable = ()=> 
      let
        objects = #table(
            {"Name",       "Key",        "Data",                           "ItemKind", "ItemName", "IsLeaf"},{
            {"Por familias de variables",      "Clasificaciones",  ISTAC.VariableFamilies() , "Folder",    "Por familias de variables",    false},
            {"fx URL de la clasificación", "GETClasificaciones", ISTAC.GETClasificaciones, "Function", "fx URL de la clasificación", true}
           }),
        NavTable = Table.ToNavigationTable(objects, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf") 
    in
        NavTable;

// Función que se encarga de obtener los datos de cubos a partir de una url
ISTAC.GETDataset = Value.ReplaceType(ISTAC.Dataset, fxCubosType);

// Metadatos para función ISTAC.GETDataset
fxCubosType = type function (
url as (type text meta [
        Documentation.FieldCaption = "url",
        Documentation.SampleValues = {"https://www3.gobiernodecanarias.org/istac/api/statistical-resources/v1.0/datasets/ISTAC/C00010A_000001/001.005"}
    ])) as table meta [                  
        Documentation.Name = "URL del cubo / consulta de datos",
        Documentation.LongDescription = "Obtiene un cubo o dataset partir de una url",
        Documentation.Examples = {[
            Description = "Obtiene un cubo o dataset partir de una url",
             Code = "Función(""https://www3.gobiernodecanarias.org/istac/api/statistical-resources/v1.0/datasets/ISTAC/C00010A_000001/001.005"")",
            Result = "Una tabla con datos de Cubos / Datasets"
        ]}
    ];

ISTAC.GETClasificaciones = Value.ReplaceType(GetClasificaciones, fxClasificacionesType);

// Metadatos para función ISTAC.GETClasificaciones
fxClasificacionesType = type function (
url as (type text meta [
        Documentation.FieldCaption = "url",
        Documentation.SampleValues = {"https://www3.gobiernodecanarias.org/istac/api/structural-resources/v1.0/codelists/ISTAC/CL_AREA_ES70_DS_20030525/01.000"}
    ])) as table meta [                  
        Documentation.Name = "URL de la clasificación",
        Documentation.LongDescription = "Obtiene los datos de clasificaciones a partir de una url",
        Documentation.Examples = {[
            Description = "Obtiene los datos de clasificaciones a partir de una url",
             Code = "Función(""https://www3.gobiernodecanarias.org/istac/api/structural-resources/v1.0/codelists/ISTAC/CL_AREA_ES70_DS_20030525/01.000"")",
            Result = "Una tabla con datos de Clasificaciones"
        ]}
    ];

// Función que se encarga de obtener los datos de indicadores y sistemas de indicadores a partir de una url
ISTAC.GETIndicadores = Value.ReplaceType(TransformBinary.Indicadores, fxIndicadoresType);    

// Metadatos para función ISTAC.GETIndicadores
fxIndicadoresType = type function (
url as (type text meta [
        Documentation.FieldCaption = "url",
        Documentation.SampleValues = {"https://www3.gobiernodecanarias.org/istac/api/indicators/v1.0/indicators/AFILIACIONES", "https://www3.gobiernodecanarias.org/istac/api/indicators/v1.0/indicatorsSystems/C00062A/indicatorsInstances/84a4dd11-dbb7-4592-8799-516d9f432688"}
    ])) as table meta [                  
        Documentation.Name = "URL del indicador / instancia de indicador",
        Documentation.LongDescription = "Obtiene los datos de indicadores y sistemas de indicadores a partir de una url",
        Documentation.Examples = {[
            Description = "Obtiene los datos de indicadores y sistemas de indicadores a partir de una url",
            Code = "Función(""https://www3.gobiernodecanarias.org/istac/api/indicators/v1.0/indicators/AFILIACIONES"")",
            Result = "Una tabla con datos de indicadores"

        ]}
    ];

// Tabla de navegación para carpetas y tablas de indicadores
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
    #"Reordered Columns" = Table.ReorderColumns(#"Renamed Columns1",{"Name", "Key", "Data", "ItemKind", "ItemName", "IsLeaf"}),
    AddSubNavTable = Table.AddColumn(#"Reordered Columns", "NewColumn", each  IndicatorSubTables ([Data] )),
    RemoveOldDataColumn = Table.RemoveColumns( AddSubNavTable, {"Data"}),
    ChangeName = Table.RenameColumns( RemoveOldDataColumn, {"NewColumn", "Data"}),
    #"Removed Other Columns" = Table.SelectColumns(ChangeName,{"Name", "Key", "Data", "ItemKind", "ItemName", "IsLeaf"}),
    TableType =  Value.ReplaceType(#"Removed Other Columns",  type table [Name= text, Key = text, Data= table, ItemKind = text, ItemName= text, IsLeaf = logical]) ,
    ToNavTable = Table.ToNavigationTable( TableType, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
in
     ToNavTable ;

// Función que crea el formato final para las tablas de indicadores
IndicatorSubTables = (x as table) => 
    let
           #"Renamed Columns" = Table.RenameColumns(x,{{"id", "Key"}, {"title.__default__", "Name"}}),
    #"Added Custom" = Table.AddColumn(#"Renamed Columns", "ItemKind", each "Table"),
    #"Duplicated Column" = Table.DuplicateColumn(#"Added Custom", "Name", "ItemName"),
    #"Added Custom1" = Table.AddColumn(#"Duplicated Column", "IsLeaf", each true),
    #"Removed Other Columns" = Table.SelectColumns(#"Added Custom1",{"Name", "Key", "Data", "ItemKind", "ItemName", "IsLeaf"}),
    ToNavTable = Table.ToNavigationTable( #"Removed Other Columns", {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
    in 
        ToNavTable;

// Función alterna creada para la paginación de diversas llamadas al API
ISTAC.AlternatePagination = (url as text, selector as text ) as table =>
let
Source = List.Generate( ()=> 
[JsonFile = Json.Document(  Web.Contents(url,[Headers=[Accept="application/json"]]) ), nextPage = JsonFile[nextLink]? ],
each [JsonFile] <> null, 
each [JsonFile = try Json.Document( Web.Contents([nextPage],[Headers=[Accept="application/json"]])) otherwise null , nextPage =try Record.Field(JsonFile, "nextLink") otherwise null  ],
each Record.Field([JsonFile], selector) ),
    Custom1 = List.Combine(Source),
    Custom2 = List.Transform( Custom1, each Table.FromRecords({_}) ),
    Custom3 = Table.Combine(Custom2)
in
    Custom3;

// Tabla de navegación para carpetas y tablas de Sistemas de indicadores
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
    ReorderColumns= Table.ReorderColumns(#"Added Custom3",{"Name", "Key", "Data", "ItemKind", "ItemName", "IsLeaf"}),
 ToNavTable = Table.ToNavigationTable(ReorderColumns , {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
in
  ToNavTable;

// Tabla de navegación para carpetas y tablas de Cubos
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
        ReorderColumns= Table.ReorderColumns(AddName,{"Name", "Key", "Data", "ItemKind", "ItemName", "IsLeaf"}),
    ToNavTable = Table.ToNavigationTable(  ReorderColumns , {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
in
  ToNavTable;

// Función que se encarga de crear la tabla final para cualquier Dataset a partir de una url
ISTAC.Dataset = (url as text) as table =>
let
  x = Binary.Buffer( Web.Contents(url , [Headers=[Accept="application/json"]]) ),
    Source = Json.Document(x),
    DatasetID = Source[id],
    DatasetName = Table.SelectRows( Table.FromRecords( Record.Field( Source[name], "text") ),  each [lang] = "es")[value]{0},
      Metadata = CubeMetadata( Source),
    ValuesColumn = CubeValuesAsTable(Source),
    DimensionColumns = CubeDimensions(Source, Metadata),
    Custom1 = Table.Paste(DimensionColumns,ValuesColumn),
    #"Changed Type with Locale" = Table.TransformColumnTypes(Custom1, {{"Valor", type number}}, "en-US"),
    Mergeperiod = Table.AddColumn( #"Changed Type with Locale" , "Fecha", each fxTextToDate([Periodo.granularity], [Periodo.code])),
    Choose = if List.Contains( Table.ColumnNames( #"Changed Type with Locale"), "Periodo.code") then Mergeperiod else    #"Changed Type with Locale",
    AddDatsetID = Table.AddColumn(Choose, "DatasetID", each DatasetID, type text),
    AddDatasetName = Table.AddColumn(AddDatsetID, "Nombre de Dataset", each DatasetName, type text),
    GrabColumnNames = Table.ColumnNames(AddDatasetName),
    ChangeName = List.Transform( GrabColumnNames, each Text.Replace(_, ".Name", ".Código")),
    ChangeLabel = List.Transform(ChangeName, each Text.Replace(_, ".label", ".Nombre")),
    ChangeGranularity = List.Transform(ChangeLabel, each Text.Replace(_, ".granularity", ".Granularidad")),
    ChangeCode = List.Transform(ChangeGranularity, each Text.Replace(_, ".code", ".Código")),
    RenameColumnsLast = Table.RenameColumns( AddDatasetName, List.Zip({GrabColumnNames,ChangeCode}) )
in
    RenameColumnsLast;

// Función de ayuda para fusionar dos tablas que tienen la misma cantidad de filas
Table.Paste = (table1, table2) => let id1 = Text.NewGuid(), id2 = Text.NewGuid() in
        Table.RemoveColumns(
            Table.Join(Table.AddIndexColumn(table1, id1), id1, 
                       Table.AddIndexColumn(table2, id2), id2,
                       JoinKind.FullOuter, JoinAlgorithm.SortMerge),
            {id1, id2});

// Función de ayuda para transformar un registro que contiene los valores de observaciones a una tabla
CubeValuesAsTable = (x as record) as table =>
let
    ValuesList = x[data],
    Values= Text.Split( ValuesList [observations], "|"), 
    Source = Table.FromList( Values, Splitter.SplitByNothing()),
    #"Renamed Columns" = Table.RenameColumns(Source,{{"Column1", "Valor"}})
in
    #"Renamed Columns";

// Función de ayuda para extraer los metadatos de un cubo que provienen de un registro 
 CubeMetadata = (x as record) as table => 
let
    metadata = x[metadata],
    dimensions = metadata[dimensions],
    dimension = dimensions[dimension],
    Custom1 = Table.FromRecords(dimension),
    #"Expanded {0}" = Table.ExpandRecordColumn(Custom1, "dimensionValues", {"value"}, {"value"}),
    #"Expanded {0}1" = Table.ExpandListColumn(#"Expanded {0}", "value"),
    #"Removed Columns2" = Table.RemoveColumns(#"Expanded {0}1",{"name"}),
    #"Added Custom4" = Table.AddColumn(#"Removed Columns2", "Personalizado", each if [id] = "TIME_PERIOD" then CubeTimeGranularities([value]) else if [id] = "MEDIDAS" then CubeMeasureGranularities([value]) else if [id]= "TERRITORIO" then CubeTerritorioGranularities([value]) else CubeGenericNoGranularities([value])),
    #"Removed Columns3" = Table.RemoveColumns(#"Added Custom4",{"value"}),
    #"Expanded {0}2" = Table.ExpandTableColumn(#"Removed Columns3", "Personalizado", {"id", "value", "Granularity"}, {"id.1", "value.1", "Granularity"}),
    #"Renamed Columns2" = Table.RenameColumns(#"Expanded {0}2",{{"id.1", "code"}, {"value.1", "value"}})
in
    #"Renamed Columns2";

// Función de ayuda para extraer los datos de granularidades de tiempo de un registro de cubo 
CubeTimeGranularities = (x as record) as table =>
let
    value1 = Table.FromRecords( {x}),
    #"Renamed Columns2" = Table.RenameColumns(value1,{{"temporalGranularity", "Granularity"}}),
    #"Expanded {0}2" = Table.ExpandRecordColumn(#"Renamed Columns2", "name", {"text"}, {"text"}),
    #"Expanded {0}3" = Table.ExpandListColumn(#"Expanded {0}2", "text"),
    #"Expanded {0}4" = Table.ExpandRecordColumn(#"Expanded {0}3", "text", {"value", "lang"}, {"value", "lang"}),
    #"Filtered Rows1" = Table.SelectRows(#"Expanded {0}4", each [lang] = "es"),
     RemoveLang = Table.RemoveColumns( #"Filtered Rows1", {"lang"})
in
   RemoveLang;

// Función de ayuda para extraer los datos de granularidades de medidas de un registro de cubo 
CubeMeasureGranularities =  (x as record) =>
let
    value1 = Table.FromRecords( {x} ),
    #"Expanded {0}" = Table.ExpandRecordColumn(value1, "name", {"text"}, {"text"}),
    #"Expanded {0}1" = Table.ExpandListColumn(#"Expanded {0}", "text"),
    #"Expanded {0}2" = Table.ExpandRecordColumn(#"Expanded {0}1", "text", {"value", "lang"}, {"value", "lang"}),
    #"Filtered Rows" = Table.SelectRows(#"Expanded {0}2", each [lang] = "es"),
    #"Removed Other Columns" = Table.SelectColumns(#"Filtered Rows",{"id", "value"})
in
    #"Removed Other Columns";

// Función de ayuda para extraer los datos de granularidades de territorios de un registro de cubo 
CubeTerritorioGranularities = (x as record) =>
let
    value = Table.FromRecords( {x} ),
    #"Expanded {0}" = Table.ExpandRecordColumn(value, "geographicGranularity", {"id", "urn", "selfLink", "name", "kind"}, {"id.1", "urn.1", "selfLink.1", "name.1", "kind.1"}),
    #"Expanded {0}1" = Table.ExpandRecordColumn(#"Expanded {0}", "name.1", {"text"}, {"text"}),
    #"Expanded {0}2" = Table.ExpandListColumn(#"Expanded {0}1", "text"),
    #"Expanded {0}3" = Table.ExpandRecordColumn(#"Expanded {0}2", "text", {"value", "lang"}, {"value", "lang"}),
    #"Expanded {0}4" = Table.ExpandRecordColumn(#"Expanded {0}3", "name", {"text"}, {"name.text"}),
    #"Expanded {0}5" = Table.ExpandListColumn(#"Expanded {0}4", "name.text"),
    #"Expanded {0}6" = Table.ExpandRecordColumn(#"Expanded {0}5", "name.text", {"value", "lang"}, {"name.text.value", "name.text.lang"}),
    #"Filtered Rows" = Table.SelectRows(#"Expanded {0}6", each [lang] = "es"),
    #"Filtered Rows1" = Table.SelectRows(#"Filtered Rows", each [name.text.lang] = "es"),
    #"Removed Other Columns1" = Table.SelectColumns(#"Filtered Rows1",{"name.text.value", "id", "id.1"}),
    #"Renamed Columns" = Table.RenameColumns(#"Removed Other Columns1",{{"name.text.value", "value"}, {"id.1", "Granularity"}})
in
    #"Renamed Columns";

// Función de ayuda para extraer los datos de granularidades que no sean de tiempo, medidas o territorios a partir de un registro de cubo
CubeGenericNoGranularities = (x as record) as table =>
let
     value1 = Table.FromRecords( { x}),
    #"Expanded name" = Table.ExpandRecordColumn(value1, "name", {"text"}, {"name.text"}),
    #"Expanded name.text" = Table.ExpandListColumn(#"Expanded name", "name.text"),
    #"Expanded name.text1" = Table.ExpandRecordColumn(#"Expanded name.text", "name.text", {"value", "lang"}, {"name.text.value", "name.text.lang"}),
    #"Filtered Rows" = Table.SelectRows(#"Expanded name.text1", each [name.text.lang] = "es"),
    #"Removed Other Columns" = Table.SelectColumns(#"Filtered Rows",{"name.text.value", "id"}),
    #"Renamed Columns" = Table.RenameColumns(#"Removed Other Columns",{{"name.text.value", "value"}})
in
    #"Renamed Columns";

// Función de ayuda para extraer los datos de dimensiones de un registro de cubo 
CubeDimensions = (x as record, y as table) as table =>
let
  Source = x[data],
  ColumnNames = CubeLabels(x),
    dimensions = Source[dimensions],
    dimension = Table.FromRecords( dimensions[dimension]),
    #"Expanded representations" = Table.ExpandRecordColumn(dimension, "representations", {"representation"}, {"representations.representation"}),
    Custom1 = Table.TransformColumns( #"Expanded representations", {{"representations.representation", Table.FromRecords }}),
    #"Transposed Table" = Table.Transpose(Custom1),
    #"Promoted Headers" = Table.PromoteHeaders(#"Transposed Table", [PromoteAllScalars=true]),
    Custom5 = Table.RenameColumns( #"Promoted Headers", ColumnNames),
    #"Expanded TERRITORIO" = List.Accumulate( List.Transform(ColumnNames, each _{1}) , 
 Custom5,
(state, column) => Table.ExpandTableColumn(state, column, {"code", "index"}, List.Transform({"code", "index"}, each Text.Combine({column,".", _ } ) )   )),
    Custom2 = List.Accumulate( ColumnNames, 
 #"Expanded TERRITORIO",
(state, column) => Table.NestedJoin(state, {column{1}&".code"}, Table.SelectRows( y, each [id]= column{0}), {"code"}, column{1}&".value" )),
    Custom3 =List.Accumulate( List.Transform(ColumnNames, each _{1}) , 
 Custom2,
(state, column) => Table.ExpandTableColumn(state, column&".value", {"value", "Granularity"}, {column&".label", column&".granularity"}   )),
    Order = List.Zip({List.Transform(List.Transform(ColumnNames, each _{1}), each _&".index"),  List.Repeat( {Order.Ascending }, List.Count(dimension[dimensionId]))}),
    Output = Table.Sort(Custom3, Order),
    Custom4 = Table.RemoveColumns( Output, List.Transform(List.Transform(ColumnNames, each _{1}), each _&".index" )),
    ColumnsSelect = List.Select( Table.ColumnNames(Custom4), each  Text.Contains(_, ".granularity")),
    ColumnsToDelete =  List.Select(ColumnsSelect, each not (Text.Contains(_, "Periodo") or Text.Contains(_, "Territorio") ) ),
    RemoveColumns = Table.RemoveColumns( Custom4, ColumnsToDelete)
in
    RemoveColumns;

// Función de ayuda para extraer los datos de etiquetadas de un registro de cubo 
CubeLabels = (x as record) =>
let
    metadata = x[metadata],
    dimensions = metadata[dimensions],
    dimension = Table.FromRecords( dimensions[dimension] ),
    #"Expanded name" = Table.ExpandRecordColumn(dimension, "name", {"text"}, {"name.text"}),
    #"Expanded name.text" = Table.ExpandListColumn(#"Expanded name", "name.text"),
    #"Expanded name.text1" = Table.ExpandRecordColumn(#"Expanded name.text", "name.text", {"value", "lang"}, {"value", "lang"}),
    #"Filtered Rows" = Table.SelectRows(#"Expanded name.text1", each ([lang] = "es")),
    #"Removed Other Columns" = Table.SelectColumns(#"Filtered Rows",{"id", "value"}),
    Custom1 = List.Zip( Table.ToColumns( #"Removed Other Columns"))
in
    Custom1;

// Función que se encarga de crear la tabla final para cualquier indicador o sistemas de indicadores a partir de una url
TransformBinary.Indicadores= (url as text) as table =>
let
    MainUrlByParts = Uri.Parts( url ),
    DataUrl = "https://"& MainUrlByParts[Host] &MainUrlByParts[Path] &"/data" & "?"& Uri.BuildQueryString( MainUrlByParts[Query]),
    DataUrlWithQuery = DataUrl &"?"& Uri.BuildQueryString( MainUrlByParts[Query]),
Metadata = Indicadores.Metadata(url),
y = Metadata[Data],
x= Binary.Buffer( Web.Contents(DataUrlWithQuery, [Headers=[Accept="application/json"]]) ),
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
     NewOne = List.Accumulate( Order, 
 Custom5,
(state, column) => Table.NestedJoin(state, {column&".Name"}, Table.SelectRows( y, each [id]= column), {"code"}, column&".value" )),
     NewOne2 = List.Accumulate( Order , 
 NewOne,
(state, column) => Table.ExpandTableColumn(state, column&".value", {"value", "Granularity", "latitude", "longitude"}, {column&".label", column&".granularity", column&".latitude", column&".longitude"}   )),
     ColumnsToOrder = List.Transform( Order, each _ &".Value"),
     ListOrder = List.Zip({ColumnsToOrder,List.Repeat({Order.Ascending}, List.Count(Order))}),
    #"Sorted Rows" = Table.Sort(NewOne2,ListOrder),
    Custom9 = #"Sorted Rows",
    observation = Table.FromList( JSON[observation]),
    Custom11 = Table.Paste(Custom9, observation),
    #"Renamed Columns1" = Table.RenameColumns(Custom11,{{"Column1", "VALUE"}}),
    #"Changed Type with Locale" = Table.TransformColumnTypes(#"Renamed Columns1", {{"VALUE", type number}}, "en-US"),
    Custom1 = Table.RemoveColumns(#"Changed Type with Locale", List.Select( Table.ColumnNames( #"Changed Type with Locale" ), each Text.Contains(_, ".Value"))),
    Custom2 = Table.RemoveColumns(Custom1, List.Select( Table.ColumnNames( Custom1 ), each  Text.Contains(_, ".granularity") and  _<>"GEOGRAPHICAL.granularity" and _ <> "TIME.granularity") ),
    Custom4 = Table.RemoveColumns(Custom2, List.Select( Table.ColumnNames( Custom2 ), each  (Text.Contains(_, ".latitude") or Text.Contains(_, ".longitude") )  and  _<>"GEOGRAPHICAL.latitude" and _ <> "GEOGRAPHICAL.longitude") ),
    #"Replaced Errors" = Table.ReplaceErrorValues(Custom4, {{"VALUE", null}}),
    AddPeriod =  Table.AddColumn( #"Replaced Errors", "Fecha" , each fxTextToDate([TIME.granularity],[TIME.Name]), type date),
    Choose = if List.Contains( Order, "TIME") then AddPeriod else #"Replaced Errors",
    AddTitle = Table.AddColumn(Choose, "Nombre de Indicador", each Metadata[Title], type text),
    AddCode = Table.AddColumn(AddTitle, "Código de Indicador", each Metadata[code], type text), 
    GrabColumnNames = Table.ColumnNames(AddCode),
    ChangeName = List.Transform( GrabColumnNames, each Text.Replace(_, ".Name", ".Código")),
    ChangeLabel = List.Transform(ChangeName, each Text.Replace(_, ".label", ".Nombre")),
    ChangeGranularity = List.Transform(ChangeLabel, each Text.Replace(_, ".granularity", ".Granularidad")),
    ChangeCode = List.Transform(ChangeGranularity, each Text.Replace(_, ".code", ".Código")),
    RenameColumnsLast = Table.RenameColumns( AddCode, List.Zip({GrabColumnNames,ChangeCode}) )
in
    RenameColumnsLast;

// Función de ayuda para extraer los metadatos de un indicador o sistema de indicadores a partir de una url
Indicadores.Metadata = (url as text) as record =>
    let 
    Custom1 = Json.Document(Web.Contents( url)),
    Code = Custom1[id],
    IndicatorSubject = Custom1[subjectTitle]?[es],
    Custom2 = Custom1[dimension],
    #"Converted to Table" = Record.ToTable(Custom2),
    #"Expanded {0}" = Table.ExpandRecordColumn(#"Converted to Table", "Value", {"code", "granularity", "representation"}, {"Value.code", "Value.granularity", "Value.representation"}),
    #"Removed Columns" = Table.RemoveColumns(#"Expanded {0}",{"Value.code"}),
    #"Expanded {0}1" = Table.ExpandListColumn(#"Removed Columns", "Value.representation"),
    #"Removed Columns2" = Table.RemoveColumns(#"Expanded {0}1",{"Value.granularity"}),
    #"Expanded {0}2" = Table.ExpandRecordColumn(#"Removed Columns2", "Value.representation", {"code", "title", "latitude", "longitude", "granularityCode"}, {"Value.representation.code", "Value.representation.title", "Value.representation.latitude", "Value.representation.longitude", "Value.representation.granularityCode"}),
    #"Expanded {0}3" = Table.ExpandRecordColumn(#"Expanded {0}2", "Value.representation.title", {"__default__"}, {"Value.representation.title.__default__"}),
    #"Removed Other Columns" = Table.SelectColumns(#"Expanded {0}3",{"Name", "Value.representation.code", "Value.representation.title.__default__", "Value.representation.latitude", "Value.representation.longitude", "Value.representation.granularityCode"}),
    #"Renamed Columns" = Table.RenameColumns(#"Removed Other Columns",{{"Name", "id"}, {"Value.representation.code", "code"}, {"Value.representation.title.__default__", "value"}, {"Value.representation.granularityCode", "Granularity"}, {"Value.representation.latitude", "latitude"}, {"Value.representation.longitude", "longitude"}}),
    Custom3 = [Data=#"Renamed Columns", code = Code, Title = Custom1[title]?[es]]
in
    Custom3;

// Tabla de navegación para carpetas y tablas de sistemas de indicadores
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
    ReorderColumns= Table.ReorderColumns(#"Removed Columns1",{"Name", "Key", "Data", "ItemKind", "ItemName", "IsLeaf"}),
    ToNavTable = Table.ToNavigationTable( ReorderColumns , {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
in
    ToNavTable ;


// Función que crea el formato final para las tablas de sistemas de indicadores
ISTAC.SystemIndicatorSubLevel = (x as table) as table =>
let
 #"Expanded title1" = Table.ExpandRecordColumn(x, "title", {"es", "__default__"}, {"title.es", "title.__default__"}),
    #"Renamed Columns1" = Table.RenameColumns(#"Expanded title1",{{"title.__default__", "Name"}, {"id", "Key"}}),
    #"Duplicated Column1" = Table.DuplicateColumn(#"Renamed Columns1", "Name", "ItemName"),
    #"Added Custom4" = Table.AddColumn(#"Duplicated Column1", "IsLeaf", each true),
    #"Added Custom5" = Table.AddColumn(#"Added Custom4", "ItemKind", each "Table"),
    #"Removed Other Columns1" = Table.SelectColumns(#"Added Custom5",{"Key", "Name", "ItemName", "IsLeaf", "Data", "ItemKind"}),
     ReorderColumns=  Table.ReorderColumns(#"Removed Other Columns1",{"Name", "Key", "Data", "ItemKind", "ItemName", "IsLeaf"}),
      ToNavTable = Table.ToNavigationTable( ReorderColumns, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
in
ToNavTable;

// Función creada específicamente para la paginación de sistemas de indicadores
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

// Tabla de navegación para carpetas y tablas de Clasificaciones
ISTAC.VariableFamilies = () as table =>
  let
   Source = ISTAC.AlternatePagination("https://www3.gobiernodecanarias.org/istac/api/structural-resources/v1.0/variablefamilies?limit=1000", "variableFamily"),
    #"Expanded selfLink" = Table.ExpandRecordColumn(Source, "selfLink", {"kind", "href"}, {"kind.1", "href"}),
    #"Expanded name" = Table.ExpandRecordColumn(#"Expanded selfLink", "name", {"text"}, {"text"}),
    #"Expanded text" = Table.ExpandListColumn(#"Expanded name", "text"),
    #"Expanded text1" = Table.ExpandRecordColumn(#"Expanded text", "text", {"value", "lang"}, {"value", "lang"}),
    #"Filtered Rows" = Table.SelectRows(#"Expanded text1", each [lang] = "es"),
    #"Added Custom" = Table.AddColumn(#"Filtered Rows", "Custom", each try ISTAC.AlternatePagination([href]&"/variables?limit=1000", "variable") otherwise error Error.Record("Sin información", "Esta variable no contiene clasificaciones", "Error")),
    #"Renamed Columns" = Table.RenameColumns(#"Added Custom",{{"id", "Key"}, {"value", "Name"}}),
    #"Duplicated Column" = Table.DuplicateColumn(#"Renamed Columns", "Name", "ItemName"),
    #"Added Custom1" = Table.AddColumn(#"Duplicated Column", "IsLeaf", each false),
    #"Added Custom2" = Table.AddColumn(#"Added Custom1", "ItemKind", each "Folder"),
    #"Removed Other Columns" = Table.SelectColumns(#"Added Custom2",{"IsLeaf", "ItemKind", "ItemName", "Custom", "Name", "Key"}),
    #"Added Custom3" = Table.AddColumn(#"Removed Other Columns", "Data", each ISTAC.VariableFamiliesLevel2 ([Custom])),
    #"Removed Columns" = Table.RemoveColumns(#"Added Custom3",{"Custom"}),
       RemoveLabels = Table.ReplaceValue( #"Removed Columns" ,"Familia de Variables de","",Replacer.ReplaceText,{"Name"}),
       RemoveLabels1 = Table.ReplaceValue( RemoveLabels ,"Familia de Variables ","",Replacer.ReplaceText,{"Name"}),
       TableOrder = Table.ReorderColumns(RemoveLabels1,{"Name", "Key", "Data", "ItemKind", "ItemName", "IsLeaf"}),
     ToNavTable = Table.ToNavigationTable( TableOrder, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
in
try ToNavTable otherwise error Error.Record("Sin información", "Esta variable no contiene clasificaciones", "Error");

// Función de ayuda que se encarga de crear el segundo nivel de la navegación de Clasificaciones
ISTAC.VariableFamiliesLevel2 = (x as table) => 
let
   #"Expanded name" = Table.ExpandRecordColumn(x, "name", {"text"}, {"text"}),
    #"Expanded text" = Table.ExpandListColumn(#"Expanded name", "text"),
    #"Expanded text1" = Table.ExpandRecordColumn(#"Expanded text", "text", {"value", "lang"}, {"value", "lang"}),
      #"Filtered Rows" = Table.SelectRows(#"Expanded text1", each ([lang] = "es")),
    #"Expanded selfLink" = Table.ExpandRecordColumn( #"Filtered Rows" , "selfLink", {"kind", "href"}, {"kind.1", "href"}),
    #"Renamed Columns" = Table.RenameColumns(#"Expanded selfLink",{{"value", "Name"}, {"id", "Key"}}),
    #"Duplicated Column" = Table.DuplicateColumn(#"Renamed Columns", "Name", "ItemName"),
    #"Added Custom1" = Table.AddColumn(#"Duplicated Column", "IsLeaf", each false),
    AddItemKind = Table.AddColumn( #"Added Custom1", "ItemKind", each "Folder"),
    #"Added Custom" = Table.AddColumn(AddItemKind, "Custom", each try ISTAC.AlternatePagination("https://www3.gobiernodecanarias.org/istac/api/structural-resources/v1.0/codelists?query=VARIABLE_URN%20EQ%20%22urn%3Asiemac%3Aorg.siemac.metamac.infomodel.structuralresources.Variable%3D" & [Key] & "%22 ", "codelist") otherwise error Error.Record("Sin información", "Esta variable no contiene clasificaciones", "Error")),
    #"Added Custom2" = Table.AddColumn(#"Added Custom", "Data", each ISTAC.VariableFamiliesLevel3([Custom])),
    #"Removed Other Columns" = Table.SelectColumns(#"Added Custom2",{"Key", "Name", "ItemName", "IsLeaf", "ItemKind", "Data"}),
   RemoveLabels = Table.ReplaceValue(  #"Removed Other Columns" ,"Variable ","",Replacer.ReplaceText,{"Name"}),
    TableOrder = Table.ReorderColumns(RemoveLabels,{"Name", "Key", "Data", "ItemKind", "ItemName", "IsLeaf"}),
     ToNavTable = Table.ToNavigationTable(  TableOrder , {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
in
try ToNavTable otherwise error Error.Record("Sin información", "Esta variable no contiene clasificaciones", "Error");

// Función de ayuda que se encarga de crear el tercer nivel de la navegación de Clasificaciones
ISTAC.VariableFamiliesLevel3 = (x as table) =>
   let
    #"Expanded name" = Table.ExpandRecordColumn(x, "name", {"text"}, {"text"}),
    #"Expanded text" = Table.ExpandListColumn(#"Expanded name", "text"),
    #"Expanded text1" = Table.ExpandRecordColumn(#"Expanded text", "text", {"value", "lang"}, {"value", "lang"}),
    #"Filtered Rows" = Table.SelectRows(#"Expanded text1", each ([lang] = "es")),
    #"Expanded selfLink" = Table.ExpandRecordColumn(#"Filtered Rows", "selfLink", {"kind", "href"}, {"kind.1", "href"}),
    #"Added Custom" = Table.AddColumn(#"Expanded selfLink", "Data", each ISTAC.VariableFamiliesLevel4( ISTAC.AlternatePagination([href] &"/codes.json?fields=+variableElement,parent", "code"  ) )),
    #"Removed Other Columns" = Table.SelectColumns(#"Added Custom",{"urn", "value", "Data"}),
    TranformUrn =  Table.TransformColumns( #"Removed Other Columns", {{"urn", each Text.Split(_, "="){1}}}),
    #"Renamed Columns" = Table.RenameColumns(TranformUrn,{{"value", "Name1"}, {"urn", "Key"}}),
    AddNewName = Table.AddColumn(#"Renamed Columns", "Name", each [Name1] & " ["& [Key]& "]"),
    #"Duplicated Column" = Table.DuplicateColumn(AddNewName, "Name", "ItemName"),
    #"Added Custom1" = Table.AddColumn(#"Duplicated Column", "IsLeaf", each true),
    AddItemKind = Table.AddColumn( #"Added Custom1", "ItemKind", each "Table"),
    TableOrder = Table.ReorderColumns(AddItemKind,{"Name", "Key", "Data", "ItemKind", "ItemName", "IsLeaf"}),
    Columns = Table.SelectColumns( TableOrder, {"Name", "Key", "Data", "ItemKind", "ItemName", "IsLeaf"}),
    ToNavTable = Table.ToNavigationTable( Columns, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
in
try ToNavTable otherwise error Error.Record("Sin información", "Esta variable no contiene clasificaciones", "Error") ;

// Función que se encarga de crear la tabla final para las Clasificaciones
ISTAC.VariableFamiliesLevel4 = (x as table) =>
    let
    RenameParent = Table.RenameColumns(x,{{"parent", "Padre"}}),
    #"Merged Queries" = Table.NestedJoin(RenameParent, {"Padre"}, RenameParent, {"urn"}, "RenameParent", JoinKind.LeftOuter),
    #"Removed Columns2" = Table.RemoveColumns(#"Merged Queries",{"Padre"}),
    #"Expanded RenameParent" = Table.ExpandTableColumn(#"Removed Columns2", "RenameParent", {"id"}, {"RenameParent.id"}),
    #"Renamed Columns2" = Table.RenameColumns(#"Expanded RenameParent",{{"RenameParent.id", "Padre"}}),
    Check1 = try List.Contains(Table.ColumnNames(#"Renamed Columns2"), "Padre") otherwise false,
    ColumnNames1 = if Check1 then {"Código", "Nombre","Idioma", "Padre"} else {"Código", "Nombre","Idioma"},
    ColumnNames2 = if Check1 then {"Código elemento de variable","Código", "Nombre","Idioma", "Padre"} else {"Código elemento de variable","Código", "Nombre","Idioma"},
    #"Se expandió name" = Table.ExpandRecordColumn(if Check1 then #"Renamed Columns2" else x, "name", {"text"}, {"name.text"}),
    #"Se expandió name.text" = Table.ExpandListColumn(#"Se expandió name", "name.text"),
    #"Se expandió name.text1" = Table.ExpandRecordColumn(#"Se expandió name.text", "name.text", {"value", "lang"}, {"name.text.value", "name.text.lang"}),
    RenameValues = Table.RenameColumns( #"Se expandió name.text1",{{"id", "Código"}, {"name.text.value", "Nombre"}, {"name.text.lang", "Idioma"}}),
    #"Expanded variableElement" = Table.ExpandRecordColumn(RenameValues, "variableElement", {"id"}, {"variableElement.id"}),
    #"Renamed Columns" = Table.RenameColumns(#"Expanded variableElement",{{"variableElement.id", "Código elemento de variable"}}),
    Choose = try Table.SelectColumns( #"Renamed Columns", ColumnNames2) otherwise Table.SelectColumns(RenameValues,ColumnNames1)
in
   try  Choose  otherwise error Error.Record("Sin información", "Esta variable no contiene clasificaciones", "Error");


// Nueva consulta para obtener datos del API de acceso a los datos de ISTAC.base
ISTAC.base = (url as text) =>
let
    Source = Json.Document(Web.Contents(url)),
    Keys = List.Transform(Source[categories], each [variable]),
    Rows = List.Transform(Source[data], each [Valor=[Valor]] & Record.FromList([dimCodes], Keys)),
    Data = Table.FromRecords(Rows),
    Cleaned = Table.SelectRows(Data, each [Valor] <> "." and [Valor] <> ".."),
    ChangedType = Table.TransformColumnTypes(Cleaned,{{"Valor", type number, "en-US"}}),
    RemovedErrors = Table.RemoveRowsWithErrors(ChangedType, {"Valor"}),
    WithLookups = List.Accumulate(
        Source[categories],
        RemovedErrors,
        (t, v) => Table.Join(
            t,
            v[variable],
            Table.FromColumns(
                {v[codes], v[codes], v[labels]},
                {v[variable], v[variable] & ".code", v[variable] & ".label"}),
            v[variable])),
    RemovedKeys = Table.RemoveColumns(WithLookups, Keys),
    WithTitle = Table.AddColumn(RemovedKeys, "Title", each Source[title])
in
    WithTitle;

// Función que se encarga de crear la tabla con datos de Clasificaciones a partir de una url
GetClasificaciones = ( url as text) as table =>
    ISTAC.VariableFamiliesLevel4( ISTAC.AlternatePagination(url &"/codes.json?fields=+variableElement,parent", "code"  ) );

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


/// Función de ayuda para crear la estructura de carpetas / jerarquías dentro de Power BI - código brindado por Microsoft
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
        tableType = Value.Type( Value.ReplaceType(table,  type table [Name= text, Key = text, Data= table, ItemKind = text, ItemName= text, IsLeaf = logical]) ),
        newTableType = (try Type.AddTableKey(tableType, keyColumns, true) otherwise  tableType )  meta 
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
// Función que transforma una cadena de texto con código de fecha a nivel granular YEARLY a una nueva cadena de texto con formato YYYYMMDD
fxYearly =  (x as text) as text => x & "0101";

// Función que transforma una cadena de texto con código de fecha a nivel granular BIYEARLY a una nueva cadena de texto con formato YYYYMMDD
fxBiYearly = (x as text) as text =>
let
GetRidOfDashes = Text.Replace(x, "-",""),
Year = Text.Start(GetRidOfDashes, 4),
ExtractText = Text.End(GetRidOfDashes,  Text.Length(GetRidOfDashes) -4), 
SplitbyH= Text.Split(ExtractText, "H" ){1},
Month = Text.PadStart( Text.From( ( Number.From(SplitbyH) - 1 ) * 6 +1 ),2,"0"),
Output = Year&Month&"01"
in
Output;

// Función que transforma una cadena de texto con código de fecha a nivel granular QUARTERLY a una nueva cadena de texto con formato YYYYMMDD
fxQuarterly = (x as text) as text =>
let
GetRidOfDashes = Text.Replace(x, "-",""),
Year = Text.Start(GetRidOfDashes, 4),
ExtractText = Text.End(GetRidOfDashes,  Text.Length(GetRidOfDashes) -4), 
SplitbyH= Text.Split(ExtractText, "Q" ){1},
Month = Text.PadStart( Text.From( ( Number.From(SplitbyH) - 1 ) * 3 +1 ),2,"0"),
Output = Year&Month&"01"
in
Output;

// Función que transforma una cadena de texto con código de fecha a nivel granular MONTHLY a una nueva cadena de texto con formato YYYYMMDD
fxMonthly = (x as text) as text =>
let
GetRidOfDashes = Text.Replace(x, "-",""),
Year = Text.Start(GetRidOfDashes, 4),
ExtractText = Text.End(GetRidOfDashes,  Text.Length(GetRidOfDashes) -4), 
SplitbyH= Text.Split(ExtractText, "M" ){1},
Month = Text.PadStart( SplitbyH,2,"0"),
Output = Year&Month&"01"
in
Output;

// Función que se encarga de transformar un texto codificado a una fecha
fxTextToDate = (granularity as text, code as text) as date =>
    let
        FunctionSelect = if granularity = "YEARLY" then fxYearly(code) else if granularity = "BIYEARLY" then fxBiYearly(code) else if granularity = "QUARTERLY" then fxQuarterly(code) else if granularity = "DAILY" then code else if granularity = "MONTHLY" then fxMonthly(code) else null,
        Year= Number.From(Text.Start(FunctionSelect,4)),
        Month = Number.From( Text.Start( Text.End(FunctionSelect,4),2)),
        Day = Number.From(Text.End( FunctionSelect, 2)),
        ToDate = #date( Year, Month, Day)
        in
            ToDate;