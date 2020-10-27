{ lib, buildPythonPackage, fetchPypi, cython, autoconf }:

buildPythonPackage rec {
  pname = "DTLSSocket";
  version = "0.1.10";

  src = fetchPypi {
    inherit pname version;
    sha256 = "0fj7ymwzp6zar7g0zhs9xhzphrb9nwn0mq59vfwv6f7cz4912wmr";
  };

  nativeBuildInputs = [ autoconf ];
  propagatedBuildInputs = [ cython ];

  # no tests upstream
  # got this error: TypeError: calling <class 'DTLSSocket.DTLSSocket.DTLSSocket'> returned <DTLSSocket.DTLSSocket.DTLSSocket object at 0x7ffff6252e50>, not a test
  doCheck = false;

  meta = with lib; {
    description = "DTLSSocket is a cython wrapper for tinydtls with a Socket like interface";
    homepage = "https://git.fslab.de/jkonra2m/tinydtls-cython";
    license = licenses.epl10;
    maintainers = with maintainers; [ kmein ];
  };
}
