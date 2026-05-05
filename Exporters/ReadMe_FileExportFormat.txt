This is the original NSB exporter. you can also try the ePhys_Toolbox\DMD_FileExporters

Exporters write standardized filename with a total of 6 fields separated by underscore '_'.
e.g. NSB_SpectralAnalysis_0000-01-00_cMet-EEG3_EEG2-02-01_4_SpectralData.csv

"NSB_{Filetype}_{RecordingDate(ISO 8601)}_{SubjectID}_{ChannelName}_{ChannelNumber}_{format}.{ext}"
	{Filetype} is hardcoded within the exporter. e.g. "SpectralAnalysis" 
	{RecordingDate} Extracted from the imported datafile. If recording date or start date is empty or "0" (i.e. .nex files) it will use the study design "Date" column data
	{SubjectID} 	Extracted from the imported datafile. If subject ID is empty it will use the study design "Date" column data. All underscores are replaced with hyphens
	{ChannelName} 	Extracted from the imported datafile.
	{ChannelNumber}	Extracted from the imported datafile.
	{format}	The type of data exported. e.g. MetaData or datatype
	{ext}		File extension (.csv, .xls, etc.)

Three files can be generated:
	1a) Metadata file and 1b) Data file/sheet as a .CSV
	2a) Metadata file and 2b) Data file/sheet as a .XLS
	3) BioBook compatible Instrument file