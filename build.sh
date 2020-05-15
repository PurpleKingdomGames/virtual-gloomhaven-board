#!/bin/bash
if !(hash elm 2>/dev/null;) then
    echo "Please install elm before continuing (https://guide.elm-lang.org/install.html)"
    exit 1
fi

if !(hash sass 2>/dev/null;) then
    echo "Please install the sass module from npm (`npm install -g sass`)"
    exit 1
fi

if !(hash uglifyjs 2>/dev/null;) then
    echo "Please install the uglify-js module from npm (`npm install -g uglify-js`)"
    exit 1
fi

echo "Setting up temporary build location"
rm -rf ./.temp-build
mkdir ./.temp-build
mkdir ./.temp-build/client
mkdir ./.temp-build/server
echo "Done setting up"

echo "Copying static files..."
if !(cp -r client/static/ .temp-build/client) then
    exit 1
fi
rm -rf ./.temp-build/scss
echo "Done!"

echo "Compiling client scripts..."
if [ "$1" = "--release" ] ; then
    if !(elm make client/src/Main.elm --output=./.temp-build/client/js/main.js --optimize) then
        exit 1
    fi

    if !(uglifyjs ./.temp-build/client/js/main.js --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' | uglifyjs --mangle --output=./.temp-build/client/js/main.min.js) then
        exit 1
    fi

    if !(sass client/static/scss:./.temp-build/client/css --update --stop-on-error --style compressed) then
        exit 1
    fi
else
    if !(elm make client/src/Main.elm --output=./.temp-build/client/js/main.min.js) then
        exit 1
    fi

    if !(sass client/static/scss:./.temp-build/client/css --update --stop-on-error) then
        exit 1
    fi
fi
echo "Done compiling!"

echo "Finishing up"
rm -rf ./build
mv ./.temp-build ./build
echo "Done!"
