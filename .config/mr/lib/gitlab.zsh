set -eo pipefail 

function flunk () {
	echo "$1" >&2
	exit 1
}

function project_list_cache () (
	test -s $cachefile || exit 1
	test $(date +%s -r $cachefile) -ge $(date +%s --date "60 min ago") || exit 1
	cat $cachefile
)

function fetch_project_list () {
	yq -re ".hosts[\"$host\"].token" ~/.config/glab-cli/config.yml || flunk "No API key for host $host"
	GITLAB_HOST=$host glab repo list --all --per-page 1000 |
		awk '/^[^ ]+\// { print $1 }' |
		sort |
		tee $cachefile
}

function list_all_projects () {
	project_list_cache || fetch_project_list
}

function list_group_projects () {
	host=${1:==gitlab.alerque.com}
	group=${2:==$USER}
	cachefile=/tmp/gitlab-repos-cache-$host
	list_all_projects |
		grep -e "^$group/" |
		while read project; do
			cat <<- EOF
				[$HOME/projects/${project}]
				checkout = GITLAB_HOST=$host glab repo clone $project -- --recursive
				update =
					git pull origin
					git submodule foreach git pull origin master
			EOF
		done
}
