all: dist/ira_layers.pmtiles

dist/ira_layers.pmtiles: temp/data_layers_detail.pmtiles temp/data_layers_dissolve.pmtiles | dist
	tile-join -o $@ $^ -pk -z10

temp/data_layers_detail.pmtiles: temp/cejst.geojson temp/ec.geojson temp/nmtc_lic.geojson temp/lic.geojson
	tippecanoe -z10 -Z8 -o $@ --coalesce-smallest-as-needed -ah -ab -S 8 \
		-L cejst_indicators:$< \
		-L energy_communities:$(word 2,$^) \
		-L alt_fuel_infra:$(word 3,$^) \
		-L low_income_communities:$(word 4,$^)

temp/data_layers_dissolve.pmtiles: temp/cejst_dissolve.geojson temp/ec_dissolve.geojson temp/afitc_dissolve.geojson temp/lic_dissolve.geojson
	tippecanoe -z7 -o $@ --coalesce-smallest-as-needed -ah -ab -S 8 \
		-L cejst_indicators:$< \
		-L energy_communities:$(word 2,$^) \
		-L alt_fuel_infra:$(word 3,$^) \
		-L low_income_communities:$(word 4,$^)

# Alternative Fuel Infrastructure Tax Credit
# Just using temp/nmtc_lic.geojson
temp/afitc_dissolve.geojson: temp/nmtc_lic.geojson 
	mapshaper $< -dissolve2 -o ndjson $@


# Energy Communities
temp/ec_dissolve.geojson: temp/ec.geojson 
	mapshaper $< -dissolve2 -o ndjson $@

temp/ec.geojson: temp/ffe_ec.geojson temp/ccec.geojson
	mapshaper $^ combine-files -union -o ndjson $@

temp/ffe_ec.geojson: data/MSA_NMSA_FEE_EC_Status_2023v2/MSA_NMSA_FEE_EC_Status_SHP_2023v2/MSA_NMSA_FEE_EC_Status_2023v2.shp
	mapshaper $< -filter 'ec_ind_qua == 1' -filter-fields ec_ind_qua -o ndjson precision=0.0001 $@

temp/ccec.geojson: data/IRA_Coal_Closure_Energy_Comm_2023v2/Coal_Closure_Energy_Communities_SHP_2023v2/Coal_Closure_Energy_Communities_SHP_2023v2.shp
	mapshaper $< -proj wgs84 -filter-fields Mine_Qual,Generator_,Neighbor_Q -o ndjson precision=0.0001 $@


# Low Income Communities
	mapshaper $^ combine-files -union -filter '(lic == "Yes"||(NAME !== null && NAME !== ""))' -filter-fields lic,PerPov1519,NAME -o ndjson $@
# ^union in prereqs fills interior polygons, need to filter out based on attrs or find a non-union method

temp/clipped_ppa.geojson: temp/usda_ppa.geojson temp/lic_dissolve.geojson
	mapshaper $< -clip $(word 2,$^) remove-slivers -o ndjson $@

temp/usda_ppa.geojson: temp/census_county_2010.shp temp/usda_ppa_county.csv
	mapshaper $< field-types=GEOID:str,fips_txt:str -join $(word 2,$^) keys=GEOID,fips_txt fields=PerPov1519 string-fields='GEOID,fips_txt' -filter 'PerPov1519 == 1' -o ndjson precision=0.0001 $@

temp/usda_ppa_county.csv: data/PovertyAreaMeasures2022.xlsx
	ogr2ogr -f "CSV" $@ -select fips_txt,PerPov1519 $< "County Measures"

temp/lic_dissolve.geojson: temp/lic_unioned.geojson
	mapshaper $< -dissolve2 -o ndjson $@

temp/lic_unioned.geojson: temp/nmtc_lic.geojson temp/tribal_lands.geojson
	mapshaper $^ combine-files -union -o ndjson $@

temp/tribal_lands.geojson: data/tl_2020_us_aitsn.shp
	mapshaper $< -filter-fields NAME -o ndjson precision=0.0001 $@

temp/nmtc_lic.geojson: temp/census_tracts_2010.shp temp/nmtc_lic.csv
	mapshaper $< field-types=GEOID:str,geoid:str -join $(word 2,$^) keys=GEOID,geoid fields=lic string-fields='GEOID,geoid,lic' -filter 'lic == "Yes"' -o ndjson precision=0.0001 $@

temp/nmtc_lic.csv: data/nmtc-2011-2015-lic-nov2-2017-4pm.xlsx
	ogr2ogr -f "CSV" $@ -sql 'SELECT "2010 Census Tract Number FIPS code. GEOID" AS geoid, "Does Census Tract Qualify For NMTC Low-Income Community (LIC) on Poverty or Income Criteria?" AS lic FROM "NMTC LICs 2011-2015 ACS"' $<


# Justice40
temp/cejst_dissolve.geojson: temp/cejst.geojson
	mapshaper $< -dissolve2 -o ndjson $@

temp/cejst.geojson: data/usa/usa.shp 
	mapshaper $< -filter 'SN_C == 1' -filter-fields $(CEJST_VARS) -o ndjson precision=0.0001 $@

# GEOID10,SN_C,EB_ET,PM25_ET
CEJST_VARS = SN_C,SN_T,DLI,ALI,PLHSE,LMILHSE,ULHSE,EPL_ET,EAL_ET,EBL_ET,EB_ET,PM25_ET,DS_ET,TP_ET,LPP_ET,HRS_ET,KP_ET,HB_ET,RMP_ET,NPL_ET,TSDF_ET,WD_ET,UST_ET,HD_ET,LLE_ET,IA_LMI_ET,IA_UN_ET,IA_POV_ET,FPL200S,TD_ET,FLD_ET,WFR_ET,ADJ_ET,IS_ET,AML_ET,FUDS_ET

#CENSUS 
temp/census_county_2010.shp: data/tlgdb_2017_a_us_substategeo.gdb
	ogr2ogr $@ -select GEOID $< County

temp/census_tracts_2010.shp: data/tlgdb_2017_a_us_substategeo.gdb
	ogr2ogr $@ -select GEOID $< Census_Tract

download:
	make -f downloads.mk

.PHONY: clean temp

dist:
	mkdir -p $@

temp:
	mkdir -p $@

data:
	mkdir -p $@

clean:
	rm -rf temp dist data