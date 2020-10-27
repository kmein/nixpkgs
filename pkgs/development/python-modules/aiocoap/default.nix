{ lib, buildPythonPackage, fetchPypi, isPy37, isPy38 }:

buildPythonPackage rec {
  pname = "aiocoap";
  version = "0.4b3";

  src = fetchPypi {
    inherit pname version;
    sha256 = "1g5fs2amdqm4ds4gpd5xiqab6z3rpg1k2brgvikla7fj9wgws9p4";
  };

  propagatedBuildInputs = [ ];

  # tests error: "TypeError: unhashable type: 'ListHandler'"
  doCheck = !isPy37 && !isPy38;

  meta = with lib; {
    description = "The Python CoAP library";
    homepage = "https://github.com/chrysn/aiocoap";
    license = licenses.mit;
    maintainers = with maintainers; [ kmein ];
  };
}
