#!/bin/bash

#############
# functions

extract_zip_files() {
	if [ ! "$(ls -A ${IMPORT_PATH})" ] ; then
		if [ "$(ls -A $DATA_PATH)" ] ; then
			cd $DATA_PATH
			for ZIP_FILE in ${DATA_PATH}/*.zip ; do
				log "Unzip ${ZIP_FILE} ..."
				if [ ! "${UNZIP_PASSWORD}" = "" ] ; then
					unzip $ZIP_FILE -d $IMPORT_PATH -P $UNZIP_PASSWORD
				else
					unzip $ZIP_FILE -d $IMPORT_PATH
				fi
				rm $ZIP_FILE
			done
		else
			log "Dateieingangsverzeichnis: ${DATA_PATH} ist leer."
		fi
	fi
}

convert_nas_files() {
	if [ "$(ls -A ${IMPORT_PATH})" ] ; then
		find ${IMPORT_PATH}/NAS -iname '*.xml' | sort |  while read NAS_FILE ; do
			NAS_FILE_=${NAS_FILE// /_} # ersetzt Leerzeichen durch _ in Dateiname
			if [ ! "$NAS_FILE" = "$NAS_FILE_" ] ; then
				echo "Benenne Datei ${NAS_FILE} um in ${NAS_FILE_}"
				mv $NAS_FILE $NAS_FILE_
				$NAS_FILE=$NAS_FILE_
			fi
			NAS_DIR=$(dirname "${NAS_FILE}")
			NAS_FILENAME=${NAS_FILE##*/}
			NAS_BASENAME=${NAS_FILENAME%.*}
			SQL_FILE="${NAS_DIR}/${NAS_BASENAME}.sql"
			GFS_FILE="${NAS_DIR}/${NAS_BASENAME}.gfs"
			
			check_dublicate=`psql -q -t -h $POSTGRES_HOST -U $POSTGRES_USER -c "SELECT count(*) FROM ${POSTGRES_SCHEMA}.import WHERE datei = '${NAS_FILENAME}' AND status='eingelesen';" $POSTGRES_DBNAME 2> ${LOG_PATH}/${ERROR_FILE}`
			if [ -n "$(grep -i 'Error\|Fehler\|FATAL' ${LOG_PATH}/${ERROR_FILE})" ] ; then
				err "Fehler beim Abfragen der import-Tabelle."
				head -n 30 ${LOG_PATH}/${ERROR_FILE}
				break
			else
				if [ ! $check_dublicate = 0 ] ; then
					log "Die NAS-Datei ${NAS_FILENAME} wurde bereits eingelesen"
					break
				else
					log "ogr2ogr konvertiert Datei: ${NAS_FILE}"
				fi
			fi

			${OGR_BINPATH}/ogr2ogr -f PGDump -append -a_srs EPSG:${EPSG_CODE} -nlt CONVERT_TO_LINEAR -lco SCHEMA=${POSTGRES_SCHEMA} -lco CREATE_SCHEMA=OFF -lco CREATE_TABLE=OFF --config PG_USE_COPY YES --config NAS_GFS_TEMPLATE "$SCRIPT_PATH/$GFS_TEMPLATE" --config NAS_NO_RELATION_LAYER YES ${SQL_FILE} ${NAS_FILE} >> ${LOG_PATH}/${LOG_FILE} 2> ${LOG_PATH}/${ERROR_FILE}
		
			#/usr/local/gdal/bin/ogr2ogr -f PGDump -append -a_srs EPSG:25833 -nlt CONVERT_TO_LINEAR -lco SCHEMA=alkis -lco CREATE_SCHEMA=OFF -lco CREATE_TABLE=OFF --config PG_USE_COPY YES --config NAS_GFS_TEMPLATE "../config/alkis-schema.gfs" --config NAS_NO_RELATION_LAYER YES /var/www/data/alkis/ff/import/NAS/nba_landmv_lro_160112_1207von2024_288000_5986000.sql /var/www/data/alkis/ff/import/NAS/nba_landmv_lro_160112_1207von2024_288000_5986000.xml

			if [ -n "$(grep -i 'Error\|Fehler\|FATAL' ${LOG_PATH}/${ERROR_FILE})" ] ; then
				err "Fehler beim Konvertieren der Datei: ${NAS_FILE}."
				head -n 30 ${LOG_PATH}/${ERROR_FILE}
				break
			else
				if [ ! -f "${IMPORT_PATH}/import_transaction.sql" ] ; then
					echo "BEGIN; SET search_path = ${POSTGRES_SCHEMA},public;" > ${IMPORT_PATH}/import_transaction.sql
				fi
				sed -i -e "s/BEGIN;//g" -e "s/END;//g" -e "s/COMMIT;//g" ${SQL_FILE}
				cat ${SQL_FILE} >> ${IMPORT_PATH}/import_transaction.sql
				echo "INSERT INTO ${POSTGRES_SCHEMA}.import (datei, status) VALUES ('${NAS_FILENAME}', 'eingelesen');" >> ${IMPORT_PATH}/import_transaction.sql
				rm ${NAS_FILE}
				rm ${SQL_FILE}
				rm -f ${GFS_FILE}
			fi
		done
	else
		log "${IMPORT_PATH} ist leer, keine NAS-Dateien zum Konvertieren vorhanden"
	fi
}

execute_sql_transaction() {
	if [ ! "$(ls -A ${IMPORT_PATH}/NAS)" ] ; then
		# ogr2ogr read all xml files successfully
		if [ -f "${IMPORT_PATH}/import_transaction.sql" ] ; then
			# execute transaction sql file
			log "Lese Transaktionsdatei ein"
			echo "END;COMMIT;" >> ${IMPORT_PATH}/import_transaction.sql
			psql -h $POSTGRES_HOST -U $POSTGRES_USER -f ${IMPORT_PATH}/import_transaction.sql $POSTGRES_DBNAME >> ${LOG_PATH}/${LOG_FILE} 2> ${LOG_PATH}/${ERROR_FILE}
			if [ -n "$(grep -i 'Error\|Fehler\|FATAL' ${LOG_PATH}/${ERROR_FILE})" ] ; then
				err "Fehler beim Einlesen der Transaktions-Datei: ${IMPORT_PATH}/import_transaction.sql."
				head -n 30 ${LOG_PATH}/${ERROR_FILE}
			else
				log "Einlesevorgang erfolgreich"
				clear_import_folder
				log "Post-Processing wird ausgeführt"
				psql -h $POSTGRES_HOST -U $POSTGRES_USER -c "SELECT ${POSTGRES_SCHEMA}.postprocessing();" $POSTGRES_DBNAME >> ${LOG_PATH}/${LOG_FILE} 2> ${LOG_PATH}/${ERROR_FILE}
				if [ -n "$(grep -i 'Error\|Fehler\|FATAL' ${LOG_PATH}/${ERROR_FILE})" ] ; then
					err "Fehler beim Ausführen der Post-Processing-Funktion : ${POSTGRES_SCHEMA}.postprocessing()"
					head -n 30 ${LOG_PATH}/${ERROR_FILE}
				else
					find ${POSTPROCESSING_PATH} -iname '*.sql' | sort |  while read PP_FILE ; do
						psql -h $POSTGRES_HOST -U $POSTGRES_USER -f ${PP_FILE} $POSTGRES_DBNAME >> ${LOG_PATH}/${LOG_FILE} 2> ${LOG_PATH}/${ERROR_FILE}
						if [ -n "$(grep -i 'Error\|Fehler\|FATAL' ${LOG_PATH}/${ERROR_FILE})" ] ; then
							err "Fehler beim Ausführen der Post-Processing-Datei : ${PP_FILE}"
						else
							log "Post-Processing erfolgreich ausgeführt"
						fi
					done
				fi				
			fi
		fi
	fi
}

clear_import_folder() {
	if [ ! "${IMPORT_PATH}" = "" ] ; then
		# import-Ordner leeren
		log "Leere Import-Ordner"
		rm -R ${IMPORT_PATH}/*
	fi
}

#LOG_LEVEL ... 0 nicht gelogged, 1 nur auf strout, 2 nur in datei, 3 stdout und datei
log() {
  if (( $LOG_LEVEL > 1 )) ; then
    echo -e "$(date): $1" >> ${LOG_PATH}/${LOG_FILE}
  fi

  if (( $LOG_LEVEL == 1 )) || (( $LOG_LEVEL == 3 )) ; then 
    echo -e $1
  fi
}

#LOG_LEVEL ... 0 nicht gelogged, 1 nur auf strout, 2 nur in datei, 3 stdout und datei
err() {
  if (( $LOG_LEVEL > 1 )) ; then
    echo -e `date`": $1" >> ${LOG_PATH}/${ERROR_FILE}
  fi

  if (( $LOG_LEVEL == 1 )) || (( $LOG_LEVEL == 3 )) ; then 
    echo -e $1
  fi
}

###############################
# Load and set config params
SCRIPT_PATH=$(dirname $(realpath $0))
CONFIG_PATH=$(realpath ${SCRIPT_PATH}/../config)
CONFIG_PHP=$(realpath ${SCRIPT_PATH}/../../../config.php)

if [ -e "${CONFIG_PATH}/config.sh" ] ; then
  source ${CONFIG_PATH}/config.sh
	POSTGRES_HOST=$(grep "'POSTGRES_HOST'" $CONFIG_PHP | cut -d"'" -f4)
	POSTGRES_USER=$(grep "'POSTGRES_USER'" $CONFIG_PHP | cut -d"'" -f4)
	POSTGRES_PASSWORD=$(grep "'POSTGRES_PASSWORD'" $CONFIG_PHP | cut -d"'" -f4)
	POSTGRES_DBNAME=$(grep "'POSTGRES_DBNAME'" $CONFIG_PHP | cut -d"'" -f4)
	if [ "$POSTGRES_DBNAME" = "" ] ; then
		POSTGRES_DBNAME=$(grep "pgdbname=" $CONFIG_PHP | cut -d"'" -f2)
	fi
  log "Konfigurationsdatei: ${CONFIG_PATH}/config.sh gelesen."
	log " Starte Import ALKIS-Daten mit Script import_nas.sh"
  log "Loglevel: ${LOG_LEVEL}"
  log "Reset Error Datei: ${LOG_PATH}/${ERROR_FILE}"
  echo `date` > "${LOG_PATH}/${ERROR_FILE}"
	log "Reset Log Datei: ${LOG_PATH}/${LOG_FILE}"
  echo `date` > "${LOG_PATH}/${LOG_FILE}"
else
  log "Konfigurationsdatei: ${CONFIG_PATH}/config.sh existiert nicht."
  log "Kopieren Sie ${CONFIG_PATH}/config-default.sh nach ${SCRIPT_PATH}/config/config.sh und passen die Parameter darin an."
	exit
fi

# ZIP-Dateien im eingang-Ordner in den import-Ordner auspacken
extract_zip_files

# NAS-Dateien im import-Ordner abarbeiten
convert_nas_files

# Transaktion ausführen
execute_sql_transaction

