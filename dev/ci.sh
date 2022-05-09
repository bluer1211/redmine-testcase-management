#!/bin/bash
#
# redmine-plugin-work-report-exporter
# Copyright (C) 2022  Sutou Kouhei <kou@clear-code.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

set -exu

source_dir=$(cd $(dirname $0)/.. && pwd)

rm -rf build
mkdir -p build
cd build

git clone \
    --depth 1 \
    --branch 4.2-stable \
    https://github.com/redmine/redmine.git \
    redmine
cd redmine

ln -s ${source_dir} plugins/testcase_management
case $1 in
    postgresql)
	sed -e 's/localhost/postgres/' \
	    plugins/testcase_management/config/database.yml.example.postgresql | tee config/database.yml
	shift
	;;
    *)
	ln -s \
	   ../plugins/testcase_management/config/database.yml.example.sqlite3 \
	   config/database.yml
	shift
	;;
esac

cat config/database.yml
cp plugins/testcase_management/test/fixtures/*.yml test/fixtures/
cp plugins/testcase_management/test/fixtures/files/*.csv test/fixtures/files/
bundle install
bin/rails db:create
bin/rails generate_secret_token
bin/rails db:migrate
bin/rails redmine:load_default_data REDMINE_LANG=en
bin/rails redmine:plugins:migrate

plugins/testcase_management/dev/run-test.sh "$@"
