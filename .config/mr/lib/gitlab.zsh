set -eo pipefail 

test -v host

cachefile=/tmp/gitlab-repos-cache-$host

function flunk () {
	echo "$1" >&2
	exit 1
}

function project_list_cache () (
	test -s ${cachefile} || exit 1
	test $(date +%s -r ${cachefile}) -ge $(date +%s --date "60 min ago") || exit 1
	cat ${cachefile}
)

function fetch_project_list () {
	yq --exit-status ".hosts[\"$host\"].token" ~/.config/glab-cli/config.yml || flunk "No API key for host $host"
	glab repo list --all --per-page 1000 |
		awk '/^[^ ]/ { print $1 }' |
		sort
}

function list_all_projects () {
	project_list_cache || fetch_project_list |
		tee ${cachefile}
}

function list_group_projects () {
	test -v 1
	list_all_projects |
		grep -ef "^$1/" |
		while read project; do
			cat <<- EOF
				[$HOME/projects/${project}]
				checkout = git clone --recursive gitlab@${host}:${project}.git
				update =
					git pull origin
					git submodule foreach git pull origin master
			EOF
		done
}
