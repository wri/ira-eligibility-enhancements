SRC = data

EC_COAL_SHP = $(SRC)/IRA_Coal_Closure_Energy_Comm_2023v2/Coal_Closure_Energy_Communities_SHP_2023v2/Coal_Closure_Energy_Communities_SHP_2023v2.shp
EC_FEE_SHP = $(SRC)/MSA_NMSA_FEE_EC_Status_2023v2/MSA_NMSA_FEE_EC_Status_SHP_2023v2/MSA_NMSA_FEE_EC_Status_2023v2.shp
TL_SHP = $(SRC)/tl_2020_us_aitsn.shp
CENSUS_GDB = $(SRC)/tlgdb_2017_a_us_substategeo.gdb
CEJST_SHP = $(SRC)/usa/usa.shp

NMTC_XLS = $(SRC)/nmtc-2011-2015-lic-nov2-2017-4pm.xlsx
USDA_XLS = $(SRC)/PovertyAreaMeasures2022.xlsx

NMTC_LIC_URL = 'https://www.cdfifund.gov/sites/cdfi/files/documents/nmtc-2011-2015-lic-nov2-2017-4pm.xlsx'
USDA_PPA_URL = 'https://www.ers.usda.gov/webdocs/DataFiles/105144/PovertyAreaMeasures2022.xlsx?v=558.3'

all: $(EC_COAL_SHP) $(EC_FEE_SHP) $(TL_SHP) $(CENSUS_GDB) $(CEJST_SHP) $(NMTC_XLS) $(USDA_XLS)

$(NMTC_XLS):
	cd $(SRC) && curl -O $(NMTC_LIC_URL)

$(USDA_XLS):
	cd $(SRC) && curl -O $(USDA_PPA_URL)

$(EC_COAL_SHP): coal_closures.zip | $(SRC) 
	unzip -DD $< -d $(SRC)

$(EC_FEE_SHP): fee_communities.zip | $(SRC) 
	unzip -DD $< -d $(SRC)

$(TL_SHP): tribal_lands.zip | $(SRC) 
	unzip -DD $< -d $(SRC)

$(CENSUS_GDB): census_tracts.zip | $(SRC) 
	unzip -DD $< -d $(SRC)

$(CEJST_SHP): cejst.zip | $(SRC) 
	unzip -DD $< -d $(SRC)
	cd $(SRC) && unzip -DD usa.zip

ZIPS := coal_closures.zip fee_communities.zip tribal_lands.zip census_tracts.zip cejst.zip

main : $(ZIPS)
	@echo Downloading source data files...

coal_closures.zip: URL:='https://edx.netl.doe.gov/resource/28a8eb09-619e-49e5-8ae3-6ddd3969e845/download?authorized=True'
fee_communities.zip: URL:='https://edx.netl.doe.gov/resource/b736a14f-12a7-4b9f-8f6d-236aa3a84867/download?authorized=True'
tribal_lands.zip: URL:='https://www2.census.gov/geo/tiger/TIGER2020/AITSN/tl_2020_us_aitsn.zip'
census_tracts.zip: URL:='https://www2.census.gov/geo/tiger/TGRGDB17/tlgdb_2017_a_us_substategeo.gdb.zip'
cejst.zip: URL:='https://static-data-screeningtool.geoplatform.gov/data-versions/1.0/data/score/downloadable/1.0-shapefile-codebook.zip'

$(ZIPS):
	curl -Lo $@ $(URL)

$(SRC):
	mkdir -p $@
