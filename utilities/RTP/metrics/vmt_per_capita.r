library(dplyr)
library(sf)

#########################################################################
# Calculates VMT per capita by place of residence and place of work
# for VMT Maps on arcgis online
# RTP 2013:
#   VMT by Place of Residence: 
#     https://mtc.maps.arcgis.com/home/item.html?id=5b11f6b61be344cdb13ffd5eacfba5eb (feature layer)
#     https://mtc.maps.arcgis.com/home/item.html?id=034f499840964a979a1572a25ac07681 (web map)
#   VMT by Place of Work:
#     https://mtc.maps.arcgis.com/home/item.html?id=24b46bec2e794a90b4aaba335b60c3bc (feature layer)
#     https://mtc.maps.arcgis.com/home/item.html?id=ece1f7085d2c4985b29d4953b63d94bb (web map)
#
# RTP 2017:
#   VMT by Place of Residence:
#     https://mtc.maps.arcgis.com/home/item.html?id=6d25504c0fde416a995d52c62a5d9e4c (feature layer)
#     https://mtc.maps.arcgis.com/home/item.html?id=2bddae2c822146a7a8e98892a6d4ee2f (web map)
#   VMT by Place of Work:
#     https://mtc.maps.arcgis.com/home/item.html?id=5264fa93cf7648469221d1405f6a3174 (feature layer)
#     https://mtc.maps.arcgis.com/home/item.html?id=6253e74fca1d463c92c15011a12a4a69 (web map)
#########################################################################
# VMT data from model output
RTP        <- 2021
RTP_DIR    <- paste0("M:/Application/Model One/RTP",RTP)
if (RTP==2013) { SCEN_DIR <- file.path(RTP_DIR, "Scenarios","Round 05 -- Final")}
if (RTP==2017) { SCEN_DIR <- file.path(RTP_DIR, "Scenarios")}
if (RTP==2021) { SCEN_DIR <- RTP_DIR}

if (RTP==2021) {
  OUTPUT_DIR <- file.path(SCEN_DIR, "Blueprint", "VMT per capita or worker")
} else {
  OUTPUT_DIR <- file.path(RTP_DIR, "VMT per capita or worker")}

OUTPUT_GIS_DIR <- file.path(OUTPUT_DIR, "GIS")

if (RTP==2013) {
  # MODEL_RUN_IDS <- c("2020_03_116", "2030_03_116", "2040_03_116")
  # 2040 is the only one with core_summaires
  MODEL_RUN_IDS <- c("2040_03_116")
} else if (RTP==2017) {
  MODEL_RUN_IDS <- c("2015_06_002", "2020_06_694", "2030_06_694", "2040_06_694_Amd1")
} else if (RTP==2021) {
  MODEL_RUN_IDS <- c("2015_TM152_IPA_17",
                     "2025_TM152_FBP_Plus_22",
                     "2030_TM152_FBP_Plus_23",
                     "2035_TM152_FBP_NoProject_24", "2035_TM152_FBP_Plus_24",
                     "2035_TM152_EIR_Alt1_06", "2035_TM152_EIR_Alt2_04",
                     "2040_TM152_FBP_Plus_24",
                     "2050_TM152_FBP_NoProject_24", "2050_TM152_FBP_PlusCrossing_24",
                     "2050_TM152_EIR_Alt1_06", "2050_TM152_EIR_Alt2_05")
}


# TAZ1454 spatial data
taz_shp <- st_read('M:\\Data\\GIS layers\\Travel_Analysis_Zones_(TAZ1454)\\Travel Analysis Zones.shp')


# Loop through runs
for (MODEL_RUN_ID in MODEL_RUN_IDS) {

  if ((RTP==2013) || (RTP==2017)) {
    vmt_data <- file.path(
      SCEN_DIR,MODEL_RUN_ID,"OUTPUT","core_summaries","AutoTripsVMT_perOrigDestHomeWork.rdata")
  } else if ((RTP==2021) && (MODEL_RUN_ID!='2015_TM152_IPA_17')) {
    vmt_data <- file.path(
      SCEN_DIR,'Blueprint', MODEL_RUN_ID,"OUTPUT","core_summaries","AutoTripsVMT_perOrigDestHomeWork.rdata")
  } else if ((RTP==2021) && (MODEL_RUN_ID=='2015_TM152_IPA_17')) {
    vmt_data <- file.path(
      SCEN_DIR,'IncrementalProgress', MODEL_RUN_ID,"OUTPUT","core_summaries","AutoTripsVMT_perOrigDestHomeWork.rdata")
  }
  print(vmt_data)
  load(vmt_data)

  # sum vmt to residence and work location
  total_vmt_by_residence <- ungroup(model_summary) %>% group_by(taz) %>% summarise(total_vmt = sum(vmt))
  total_vmt_by_workplace <- ungroup(model_summary) %>% group_by(WorkLocation) %>% summarise(total_vmt = sum(vmt))
  
  
  if ((RTP==2013) || (RTP==2017)) {
    persons_data <- file.path(
      SCEN_DIR,MODEL_RUN_ID,"OUTPUT","core_summaries","AutoTripsVMT_personsHomeWork.rdata")
  } else if ((RTP==2021) && (MODEL_RUN_ID!='2015_TM152_IPA_17')) {
    persons_data <- file.path(
      SCEN_DIR,'Blueprint', MODEL_RUN_ID,"OUTPUT","core_summaries","AutoTripsVMT_personsHomeWork.rdata")
  } else if ((RTP==2021) && (MODEL_RUN_ID=='2015_TM152_IPA_17')) {
    persons_data <- file.path(
      SCEN_DIR,'IncrementalProgress', MODEL_RUN_ID,"OUTPUT","core_summaries","AutoTripsVMT_personsHomeWork.rdata")
  }
  print(persons_data)
  load(persons_data)

  # sum population to residence and work location
  total_pop_by_residence <- ungroup(model_summary) %>% group_by(taz) %>% summarise(total_pop = sum(freq))
  total_pop_by_workplace <- ungroup(model_summary) %>% group_by(WorkLocation) %>% summarise(total_pop = sum(freq))
  
  # join it up
  vmt_pop_by_residence <- merge(total_vmt_by_residence, total_pop_by_residence, by="taz", all=TRUE) %>%
    mutate(vmtpercapita=total_vmt/total_pop)

  vmt_pop_by_workplace <- merge(total_vmt_by_workplace, total_pop_by_workplace, by="WorkLocation", all=TRUE) %>%
    mutate(vmtperworker=total_vmt/total_pop)
  
  # write it
  write.csv(vmt_pop_by_residence, file.path(OUTPUT_DIR, paste0("Home_",MODEL_RUN_ID,".csv")), row.names=FALSE)
  write.csv(vmt_pop_by_workplace, file.path(OUTPUT_DIR, paste0("Work_",MODEL_RUN_ID,".csv")), row.names=FALSE)

  # join to TAZ1454 shapes
  vmt_pop_by_residence <- vmt_pop_by_residence %>% rename('TAZ1454' = 'taz')
  vmt_pop_by_workplace <- vmt_pop_by_workplace %>% rename('TAZ1454' = 'WorkLocation')
  vmt_pop_by_residence_shp <- taz_shp %>% left_join(vmt_pop_by_residence, by='TAZ1454')
  vmt_pop_by_workplace_shp <- taz_shp %>% left_join(vmt_pop_by_workplace, by='TAZ1454')
  
  # write it
  st_write(vmt_pop_by_residence_shp, file.path(OUTPUT_GIS_DIR, paste0("Home_",MODEL_RUN_ID,".shp")))
  st_write(vmt_pop_by_workplace_shp, file.path(OUTPUT_GIS_DIR, paste0("Work_",MODEL_RUN_ID,".shp")))
}

