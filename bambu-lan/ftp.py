#!/usr/bin/env python3
"""Upload/list files on the A1's SD card via implicit FTPS (port 990).
  python3 ftp.py list
  python3 ftp.py upload local_file [remote_name]
"""
import ftplib, os, ssl, sys

HOST = os.environ["BAMBU_HOST"]
CODE = os.environ["BAMBU_ACCESS_CODE"]

class ImplicitFTPS(ftplib.FTP_TLS):
    """Implicit TLS + reuse the control session on data connections (printer requires it)."""
    def __init__(self, *a, **kw):
        super().__init__(*a, **kw); self._sock = None
    @property
    def sock(self): return self._sock
    @sock.setter
    def sock(self, v):
        if v is not None and not isinstance(v, ssl.SSLSocket):
            v = self.context.wrap_socket(v)
        self._sock = v
    def ntransfercmd(self, cmd, rest=None):
        conn, size = ftplib.FTP.ntransfercmd(self, cmd, rest)
        if self._prot_p:
            conn = self.context.wrap_socket(conn, server_hostname=self.host, session=self.sock.session)
        return conn, size
    def storbinary(self, cmd, fp, blocksize=32768):
        # Printer never answers the TLS close_notify, so skip conn.unwrap() (stock ftplib hangs there)
        self.voidcmd("TYPE I")
        with self.transfercmd(cmd) as conn:
            while buf := fp.read(blocksize):
                conn.sendall(buf)
        return self.voidresp()

def connect():
    ctx = ssl.create_default_context(); ctx.check_hostname = False; ctx.verify_mode = ssl.CERT_NONE
    f = ImplicitFTPS(context=ctx, timeout=20)
    f.connect(HOST, 990); f.login("bblp", CODE); f.prot_p()
    return f

if __name__ == "__main__":
    f = connect()
    if sys.argv[1] == "upload":
        src = sys.argv[2]; dst = sys.argv[3] if len(sys.argv) > 3 else os.path.basename(src)
        with open(src, "rb") as fh: f.storbinary(f"STOR {dst}", fh)
        print(f"uploaded {src} -> /{dst} ({os.path.getsize(src)} bytes)")
    f.retrlines("LIST")
    f.quit()
