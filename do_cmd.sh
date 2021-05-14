#set -x
set -euo pipefail

WORKING_DIR="$(pwd)"

MY_DIR="$(cd "$(dirname "$0")" && pwd)"
pushd "${MY_DIR}" &>/dev/null || exit 1
DOC_FOLDER_PROD="docs_from_gdrive"
PREPROD_FOLDER="gitelesmelezes"


function log {
    echo -e "$(date +'%Y-%m-%d %H:%M:%S'):INFO: ${*} " >&2;
}

function usage {
cat << EOF
usage: ${0} <command> [<args>]

These are  ${0} commands used in various situations:

    build-site            Prepare dist directory with landing pages and documentation
    preview-pages Starts the web server with preview of the website
    build-doc            Builds doc from gsuite
    copy-doc            copy last version of doc to site folder
    build-pages            Builds pages
    install-node-deps     Download all the Node dependencies
    check-site-links      Checks if the links are correct in the website
    lint-css              Lint CSS files
    lint-js               Lint Javascript files
    help                  Display usage
    check-a11y             check a11y compliance

Unrecognized commands are run as programs in the container.

For example, if you want to display a list of files, you
can execute the following command:

    $0 ls

The following command can also be performed from the Docker environment:
install-node-deps, preview, build-site, lint-css, lint-js.

The lint-css and lint-js accept paths in arguments. If no path is given, the script
will be executed for all supported files

EOF
}




function relativepath {
    source=$1
    target=$2
    
    common_part=$source # for now
    result="" # for now
    
    while [[ "${target#$common_part}" == "${target}" ]]; do
        # no match, means that candidate common part is not correct
        # go up one level (reduce common part)
        common_part="$(dirname "$common_part")"
        # and record that we went back, with correct / handling
        if [[ -z $result ]]; then
            result=".."
        else
            result="../$result"
        fi
    done
    
    if [[ $common_part == "/" ]]; then
        # special case for root (no common path)
        result="$result/"
    fi
    
    # since we now have identified the common part,
    # compute the non-common part
    forward_part="${target#$common_part}"
    
    # and now stick all parts together
    if [[ -n $result ]] && [[ -n $forward_part ]]; then
        result="$result$forward_part"
        elif [[ -n $forward_part ]]; then
        # extra slash removal
        result="${forward_part:1}"
    fi
    echo "$result"
}

function run_command {
    log "Running command: $* in $(pwd)"
    working_directory=$1
    shift
    pushd "${working_directory}"
    $@
    popd &>/dev/null
    
}

function run_lint {
    script_working_directory=$1
    command=$2
    shift 2
    
    DOCKER_PATHS=()
    for E in "${@}"; do
        ABS_PATH=$(cd "${WORKING_DIR}" && realpath "${E}")
        DOCKER_PATHS+=("$(relativepath "$(pwd)" "${ABS_PATH}")")
    done
    run_command "${script_working_directory}" "${command}" "${DOCKER_PATHS[@]}"
}


function build_pages {
    RELEASE=$1
    log "Building pages for ${RELEASE}"
    copy_doc ${RELEASE}
    run_command "site-content/"  rm -rf dist
    if [[ "${RELEASE}" == "preproduction" ]]; then
        run_command "site-content/" npm run  dev
    else
        run_command "site-content/" npm run build
        
        
    fi
    deploy_pages ${RELEASE}
    
}
function deploy_pages {
    log "Deploying landing pages"
    RELEASE=$1
    
    mkdir -p dist
    mkdir -p dist/${RELEASE}
    rm -rf dist/${RELEASE}/*
    
    
    verbose_copy site-content/dist/. dist/${RELEASE}/
    if [[ "${RELEASE}" == "preproduction" ]]; then
        if [[ -z "${URL_PREPROD+x}" ]]; then
            echo "URL_PREPROD environment variable not set"
            exit 0
        else
            log "Copy dist in /var/www/html/${PREPROD_FOLDER} for preprod tests"
            sudo mkdir -p /var/www/html/${PREPROD_FOLDER}
            sudo rm -rf /var/www/html/${PREPROD_FOLDER}/*;sudo cp -rp dist/${RELEASE}/* /var/www/html/${PREPROD_FOLDER}
            
            sudo sed -i "s/https:\/\/${URL_PROD}/http:\/\/${URL_PREPROD}\//g" /var/www/html/${PREPROD_FOLDER}/sitemap.xml
            sudo sed -i "s/https:\/\/${URL_PROD}/http:\/\/${URL_PREPROD}\//g" /var/www/html/${PREPROD_FOLDER}/robots.txt
            
            for page in $(find /var/www/html/${PREPROD_FOLDER} -name "*.html"); do
                sudo sed -i "s/https:\/\/${URL_PROD}/http:\/\/${URL_PREPROD}\//g" ${page}
                
            done
            
        fi
        elif [[ "${RELEASE}" == "production" ]]; then
        if [[ -z "${SSH_PROD+x}" ]]; then
            echo "SSH_PROD environment variable not set"
            exit 0
        else
            rsync -rh --progress dist/${RELEASE}/* ${SSH_PROD}
            exit 0
        fi
    fi
}



function verbose_copy {
    source="$1"
    target="$2"
    log "Copying '$source' to '$target'"
    mkdir -p "${target}"
    cp -R "$source" "$target"
}



function build_site {
    log "Building full site"
    build_doc
    copy_doc
    build_pages
    
    
}
function build_doc {
    log "Building doc from gdrive"
    rm -rf "${DOC_FOLDER_PROD}/*"
    
    python -m gstomd --folder_id ${DOC_GDRIVE_PROD}  --dest "${DOC_FOLDER_PROD}" --config "conf/pydrive_settings.yaml"
    
}

function copy_doc {
    RELEASE="$1"
    log "copy_doc for ${RELEASE}"
    
    
    for collection in ${DOC_FOLDER_PROD}/gitelesmelezesfr/* ; do
        # Process directories only,
        if [ ! -d "${collection}" ]; then
            continue;
        fi
        collection_name="$(basename -- "${collection}")"
        mkdir -p "site-content/src/${collection_name}/"
        find  "site-content/src/${collection_name}/"  -maxdepth 1 -mindepth 1 -type d -exec  rm -rf {} +
        
        verbose_copy "${collection}/." "site-content/src/${collection_name}"
        
    done
    if [[ "${RELEASE}" == "production" ]]; then
        log "remove drafts"
        find  "site-content/src/"  -type d -name 'drafts' -exec  rm -rf {} +
    fi
}
function build_site {
    log "Building full site"
    
    build_doc
    log "... for preproduction"
    
    copy_doc preproduction
    build_pages preproduction
    
    log "... for production"
    
    copy_doc production
    build_pages production
    
    
}





function check_a11y {
    log "Checking a11y compliance... "
    if [[ -z "${URL_PREPROD+x}" ]]; then
        echo "you must set URL_PREPROD environment variable"
        exit 1
    fi
    
    pa11y-ci --sitemap "http://$URL_PREPROD"/sitemap.xml
    
}


# - - - - - MAIN
if [[ ! -f conf/conf-secret.sh ]] ; then
    log "Missing configuration file conf/conf-secret.sh"
    exit 1
fi

. ./conf/conf-secret.sh


if [[ "$#" -eq 0 ]]; then
    echo "You must provide at least one command."
    echo
    usage
    exit 1
fi

CMD=$1

shift



if [[ "${CMD}" == "install-node-deps" ]] ; then
    run_command "site-content/" npm install
    elif [[ "${CMD}" == "preview-pages" ]]; then
    run_command "site-content/" npm run preview
    elif [[ "${CMD}" == "build-pages-preprod" ]]; then
    build_pages preproduction
    elif [[ "${CMD}" == "build-pages-prod" ]]; then
    build_pages production
    elif [[ "${CMD}" == "build-site" ]]; then
    build_site
    elif [[ "${CMD}" == "build-doc" ]]; then
    build_doc
    elif [[ "${CMD}" == "copy-doc" ]]; then
    copy_doc
    elif [[ "${CMD}" == "check-site-links" ]]; then
    run_command "site-content/" ./check-links.sh
    
    elif [[ "${CMD}" == "check-a11y" ]]; then
    check_a11y
    elif [[ "${CMD}" == "lint-js" ]]; then
    if [[ "$#" -eq 0 ]]; then
        run_command "site-content/" npm run lint:js
    else
        run_lint "site-content/" ./node_modules/.bin/eslint "$@"
    fi
    elif [[ "${CMD}" == "lint-css" ]]; then
    if [[ "$#" -eq 0 ]]; then
        run_command "site-content/" npm run lint:css
    else
        run_lint "site-content/" ./node_modules/.bin/stylelint "$@"
    fi
    
fi

popd &>/dev/null || exit 1
