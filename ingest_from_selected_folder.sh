#!/usr/bin/env bash

DUMP_HOST='storage.jupiter.bbc.co.uk'
NT_INGEST_HOST='zgbwcJNTfs7601.jupiter.bbc.co.uk'
DUMP_USER='npf'
DUMP_PW='npf'
MOUNT_PT=dump
MEDIA_LIB_LOC="./$MOUNT_PT/00_test_media_library"
INGEST_LOC='/var/bigpool/JupiterNT/test_ingest/davina'
CURRENT_TIMESTAMP_WITH_MS=$(date +"%Y-%m-%dT%T.818Z")
CURRENT_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILE_EXTS=('mxf' 'mov' 'avi' 'wav' 'ts' 'bim' 'ppn' 'smi' 'ind' 'bmp' 'mp4')
FIND_FILES_CMD="find ."
TMP_DIR=to_be_ingested_tmp2

SOURCE_FILE=$1


 splash() {
    echo ">>>>>> WELCOME TO THE WIZARD FOR INGESTING MEDIA CONTENT FROM ANY CHOSEN LOCAL FOLDER ONTO NT <<<<<<"
    sleep 2
 }

  mkdir_test() {
    if [ ! -d "$1" ]; then
       echo "... you dont have $1 directory, will make it now"
       mkdir $1
    else
       echo "... you have $1 directory already"
    fi
 }

 sending_auth() {
    echo $1
    sleep 2
    ssh-copy-id -i ~/.ssh/id_rsa.pub $2
    sleep 2
 }


gen_xml() {
     echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
    <newsMessage xmlns=\"http://iptc.org/std/nar/2006-10-01/\" xmlns:php=\"http://php.net/xsl\" xmlns:xhtml=\"http://www.w3.org/1999/xhtml\" xmlns:jupiter=\"http://jupiter.bbc.co.uk/newsml\" >
        <header>
            <sent>$CURRENT_TIMESTAMP_WITH_MS</sent>
            <sender>Shoot edit tool</sender>
            <priority>4</priority>
        </header>
        <itemSet>
            <newsItem standard=\"NewsML-G2\" standardversion=\"2.25\" conformance=\"power\" guid=\"$UUID\"  >
                <catalogRef href=\"http://www.iptc.org/std/catalog/catalog.IPTC-G2-Standards_22.xml\"/>
                <rightsInfo>
                    <copyrightHolder  literal=\"TEST 2\" jupiter:item=\"summarycopyrightholder\">
                        <name>BSD</name>
                    </copyrightHolder>
                    <usageTerms jupiter:item_trafficlightdescription=\"RED\">WARNING THIS A TRAFFICLIGHT DESCRIPTION

                        This content is for testing  purposes only.</usageTerms>
                </rightsInfo>
                <itemMeta>
                    <itemClass qcode=\"ninat:video\"/>
                    <provider qcode=\"nprov:BBC\"/>
                    <versionCreated jupiter:item=\"arrivaldatetime\">$CURRENT_TIMESTAMP_WITH_MS</versionCreated>
                    <generator/>
                    <profile/>
                </itemMeta>
                <contentMeta>
                    <contentCreated jupiter:item=\"creationdatetime\">$CURRENT_TIMESTAMP_WITH_MS</contentCreated>
                    <contentModified>2020-03-16T13:00:51.818Z</contentModified>

                    <creator jupiter:item=\"createdbyuser\">
                        <name>Ivan</name>
                    </creator>
                    <slugline jupiter:item=\"storyname\">zzivan</slugline>
                    <headline jupiter:item=\"details\">ingest test for JUPITER-1888 ($SOURCE_FILE)</headline>
                    <description jupiter:item=\"description\">
                        this is to test ingest for $SOURCE_FILE
                     </description>

                    <keyword/>
                    <language tag=\"en-GB\"/>
                    <jupiter:outlet>News</jupiter:outlet>
                    <jupiter:mediastatus>Rough Cut</jupiter:mediastatus>
                    <jupiter:mediacategory>Fimport</jupiter:mediacategory>
                    <jupiter:description>
                        <jupiter:sourcedescription>BSD</jupiter:sourcedescription>
                        <jupiter:crewcamerman>Ivan</jupiter:crewcamerman>
                    </jupiter:description>
                </contentMeta>
            </newsItem>
        </itemSet>
    </newsMessage>
    " > $1
 }

 ingest() {
    echo "1) Just gonna create a temp folder to gather all the essential files for ingesting ..."
    sleep 2
    mkdir_test $TMP_DIR

    echo "2) copying over the file to temp dir ..."
    sleep 2

    source1=$(echo $@ | sed s'/ /\*/g')

    cp $source1 ./$TMP_DIR

    echo "3) generating MD5 for this file ..."
    filename=$(echo $1 | rev | cut -d'/' -f1 | rev )
    sleep 2
    md5sum ./"$TMP_DIR"/"$filename" | cut -d' ' -f1 > ./"$TMP_DIR"/"$filename".md5

    echo "4) will generate the xml file now... "
    sleep 2
    gen_xml ./"$TMP_DIR"/"$filename".xml

    echo "5) I will create a new folder in NT ($NT_INGEST_HOST).. please log in with your jupiter password if this is the first time this script is run ..."
    sleep 2
    dest_dir=$(echo $1 |  sed s'/[ ]/_/g');
    ssh $NT_INGEST_HOST "cd $INGEST_LOC;
    mkdir ivan-$CURRENT_TIMESTAMP;
    cd ivan-$CURRENT_TIMESTAMP;
    mkdir $dest_dir;
    cd $dest_dir"

    echo "6) will begin SCP the contents of the temp dir to this folder"
    sleep 2
    cd ./"$TMP_DIR"/

    dest_host_filepath=$NT_INGEST_HOST:$INGEST_LOC/ivan-$CURRENT_TIMESTAMP/$dest_dir/
    scp ./"$filename" ./"$filename".xml ./"$filename".md5 $dest_host_filepath
    cd ..
    rm -rf ./"$dest_dir"
 }


 splash
 sending_auth " .. sending authorisation keys to the destination NT server where the contents are, please log in with your JUPITER domain password if first time ... " $NT_INGEST_HOST
 ingest "${SOURCE_FILE}"
