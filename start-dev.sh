#!/bin/sh
# NOTE: mustache templates need \ because they are not awesome.
exec erl -pa ebin edit deps/*/ebin -boot start_sasl \
	-pa libs/*/ebin/ \
    -sname imgRes_dev \
    -cookie hola \
    -s imgRes \
    -s reloader
