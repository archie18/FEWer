export AMBER_PREFIX="/opt/biology/amber16"
export AMBERHOME=/opt/biology/amber16
export PATH="${AMBER_PREFIX}/bin:${PATH}"
# Add location of Amber Python modules to default Python search path
if [ -z "$PYTHONPATH" ]; then
    export PYTHONPATH="${AMBER_PREFIX}/lib/python2.7/site-packages"
else
    export PYTHONPATH="${AMBER_PREFIX}/lib/python2.7/site-packages:${PYTHONPATH}"
fi
if [ -z "${LD_LIBRARY_PATH}" ]; then
   export LD_LIBRARY_PATH="${AMBER_PREFIX}/lib"
else
   export LD_LIBRARY_PATH="${AMBER_PREFIX}/lib:${LD_LIBRARY_PATH}"
fi
