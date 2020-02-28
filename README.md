# istacPowerBI

#### Extensión para Microsoft PowerBI de conexión a la Infraestructura de Datos y Metadatos Estadísticos de Canarias (eDatos) que permite la interoperabilidad de la herramienta con los datos abiertos publicados en eDatos con el fin de importarlos de manera automática y muy sencilla. La información que puede conectarse es las siguiente:

1. Indicadores: Permite obtener los datos de los indicadores y sus instancias publicados en la API de indicadores (https://www.gobiernodecanarias.org/istac/api/indicators/v1.0/#)
1. Cubos: Permite obtener los datos de los cubos de datos y sus consultas publicados en la API de recursos estadísticos (https://www.gobiernodecanarias.org/istac/api/statistical-resources/v1.0/)
1. Clasificaciones: Permite obtener cualquier clasificación usada por el ISTAC para codificar sus cubos de datos, y además facilitar la recodificación de variables, utilizando para ello la información publicada en la API de recursos estructurales (https://www.gobiernodecanarias.org/istac/api/structural-resources/v1.0/#/)
 
#### Para instalar el conector debes seguir los siguientes pasos:

1. Descargar el fichero ISTAC.mez del repositorio. 
1. Instalar Power BI Desktop (https://powerbi.microsoft.com/es-es/downloads/ )
1. Seguir los pasos para poder usar conectores no certificados: https://docs.microsoft.com/es-es/power-bi/desktop-connector-extensibility
1. Reiniciar Power BI Desktop tras habilitar los custom connectors

#### Estos tres pasos solo se deben realizar la primera vez. Cuando el conector haya pasado por el proceso de certificación de Microsoft no será necesario proceder a la instalación. Para el acceso al conector se deben seguir los siguientes pasos:

1. Desde el Power BI Desktop seleccionar la opción “Obtener Datos”.
1. Ahí verás el conector (ISTAC – Datos y metadatos). Selecciona esa opción y haz clic en conectar. 

![Logo interreg](http://www.gobiernodecanarias.org/istac/galerias/imagenes/mac/mac-interreg.png)
