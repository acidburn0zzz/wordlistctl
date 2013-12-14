#!/bin/sh
################################################################################
#                                                                              #
# wordlistctl.sh - fetch and install wordlists                                 #
#                                                                              #
# FILE                                                                         #
# wordlistctl.sh                                                               #
#                                                                              #
# DATE                                                                         #
# 2013-12-07                                                                   #
#                                                                              #
# DESCRIPTION                                                                  #
# This script can fetch and install wordlists from various sites.              #
#                                                                              #
# AUTHORS                                                                      #
# teitelmanevan@gmail.com                                                      #
# noptrix@nullsecurity.net                                                     #
# archey@riseup.net                                                            #
# nrz@nullsecurity.net                                                         #
#                                                                              #
################################################################################


# wordlistctl.sh version
VERSION="wordlistctl.sh v0.1"

# verbose mode - default: quiet
VERBOSE="/dev/null"

# debug mode - default: off
DEBUG="/dev/null"

# wordlist base directory
LIST_DIR="/usr/share/wordlists"

# user agent string for curl
USERAGENT="blackarch/${VERSION}"

# default wordlist list
#    name | size (human readable) | url
URL_FILE="/usr/share/wordlistctl/wordlists.lst"

# use colors
COLORS=true

# clean up downloaded archives after extraction
CLEAN=true

# print line in blue
blue()
{
    msg="${*}"

    if ${COLORS}
    then
        echo "`tput setaf 4``tput bold`${msg}`tput sgr0`"
    else
        echo "${msg}"
    fi
}


# print line in yellow
yellow()
{
    msg="${*}"

    if ${COLORS}
    then
        echo "`tput setaf 3``tput bold`${msg}`tput sgr0`"
    else
        echo "${msg}"
    fi
}


# print line in green
green()
{
    msg="${*}"

    if ${COLORS}
    then
        echo "`tput setaf 2``tput bold`${msg}`tput sgr0`"
    else
        echo "${msg}"
    fi
}


# print line in red
red()
{
    msg="${*}"

    if ${COLORS}
    then
        echo "`tput setaf 1``tput bold`${msg}`tput sgr0`"
    else
        echo "${msg}"
    fi
}


# print warning
warn()
{
    red "[!] WARNING: ${*}"
}


# print error and exit
err()
{
    red "[-] ERROR: ${*}"
    exit 1
}


# list wordlists
# TODO: finish
list()
{
	blue "[*] available wordlists"
	IFS='|'
	while read name size url ; do
		echo "name: $name"
		echo "size: $name"
		echo "url: $name"
	done < "${LIST_FILE}"
}


# extract exploit archives
extract()
{
    blue "[*] extracting wordlist archives"

	:
}


# get an entry from a list
get_entry()
{
	sed -n "${1}p"
}


# get entry name
entry_get_name()
{
	cut -d'|' -f1 < ${LIST_FILE}
}


# get entry size
entry_get_size()
{
	cut -d'|' -f2 < ${LIST_FILE}
}


# get entry url
entry_get_url()
{
	cut -d'|' -f3 < ${LIST_FILE}
}


# update exploit directory / fetch new exploit archives
update()
{
    blue "[*] updating exploit collection"

    # there is currently no need for doing checks and updates
    green "  -> updating exploit-db ..." > ${VERBOSE} 2>&1
    fetch_xploitdb
    extract_xploitdb

    green "  -> updating packetstorm ..." > ${VERBOSE} 2>&1
}


# download wordlist archives from chosen sites
fetch()
{
	url=`get_entry < ${LIST_FILE} | get_url`
	curl -O "$url"
}


# usage and help
usage()
{
    echo "usage:"
    echo ""
    echo "  wordlistctl.sh -f <arg> | -u <arg> | -s <arg> [options] | <misc>"
    echo ""
    echo "options:"
    echo ""
    echo "  -f <num>    - download and extract wordlists from chosen"
    echo "                websites - ? to list wordlists"
    echo "  -u <num>    - update wordlists from chosen"
    echo "                websites - ? to list wordlists"
    echo "  -e <dir>    - wordlist directory (default: /usr/share/wordlists)"
    echo "  -l <file>   - wordlist list"
    echo "                (default: /usr/share/wordlistctl/wordlists)"
    echo "  -c          - do not delete downloaded archive files"
    echo "  -n          - turn off colors"
    echo "  -v          - verbose mode (default: off)"
    echo "  -d          - debug mode (default: off)"
    echo ""
    echo "misc:"
    echo ""
    echo "  -V      - print version and exit"
    echo "  -H      - print this help and exit"

    exit
}


# leet banner, very important
banner()
{
    yellow "--==[ wordlistctl.sh by blackarch.org ]==--"
}


# check chosen website
check_site()
{
    if [ "${site}" = "?" ]
    then
		list
        exit
    elif [ "${site}" -lt "0" -o "${site}" -gt `wc -l < ${LIST_FILE}` ]
    then
        err "unknown wordlist"
    fi
}


# check argument count
check_argc()
{
    if [ ${#} -lt 1 ]
    then
        err "-H for help and usage"
    fi
}


# check if required arguments were selected
check_args()
{
    blue "[*] checking arguments" > ${VERBOSE} 2>&1

    if [ -z "${job}" ]
    then
        err "choose -f, -u or -s"
    fi

    if [ "${job}" = "search_web" ] && [ ! -f "${URL_FILE}" ]
    then
        err "failed to get url file for web searching - try -l <file>"
    fi
}


# parse command line options
get_opts()
{
    while getopts f:u:s:w:e:b:l:cnvdVH flags
    do
        case ${flags} in
            f)
                site="${OPTARG}"
                job="fetch"
                ;;
            u)
                site="${OPTARG}"
                job="update"
                ;;
            s)
                srch_str="${OPTARG}"
                job="search_db"
                ;;
            w)
                srch_str="${OPTARG}"
                job="search_web"
                ;;
            e)
                LIST_DIR="${OPTARG}"
                ;;
            l)
                LIST_FILE="${OPTARG}"
                ;;
            c)
                CLEAN=0
                ;;
            n)
                COLORS=0
                ;;
            v)
                VERBOSE="/dev/stdout"
                ;;
            d)
                DEBUG="/dev/stdout"
                ;;
            V)
                echo "${VERSION}"
                exit
                ;;
            H)
                usage
                ;;
            *)
                err "WTF?! mount /dev/brain"
                ;;
        esac
    done
}


# controller and program flow
main()
{
    check_argc "${@}"
    get_opts "${@}"
    banner
    check_args "${@}"

    if [ "${job}" = "fetch" ]
    then
		check_site
        fetch
        extract
        clean
    elif [ "${job}" = "update" ]
    then
		check_site
        update
        clean
    elif [ "${job}" = "search_db" ]
    then
        search_db
    elif [ "${job}" = "search_web" ]
    then
        search_web
    else
        err "WTF?! mount /dev/brain"
    fi

    blue "[*] game over"
}


# program start
main "${@}"

# EOF
