{ lib, buildPythonPackage, fetchPypi, aiocoap, DTLSSocket }:

buildPythonPackage rec {
  pname = "pytradfri";
  version = "7.0.2";

  src = fetchPypi {
    inherit pname version;
    sha256 = "1k15k07wh0x987ibgwf4w0gqz35qlvp2rg6l7makj1i3ilqa21a6";
  };

  propagatedBuildInputs = [ aiocoap DTLSSocket ];

  meta = with lib; {
    description = "IKEA Trådfri/Tradfri API. Control and observe your lights from Python.";
    homepage = "https://github.com/home-assistant-libs/pytradfri";
    license = licenses.mit;
    maintainers = with maintainers; [ kmein ];
  };
}
