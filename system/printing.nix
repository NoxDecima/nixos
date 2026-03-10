{ ... }:
{

    services.printing.enable = true;

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    # Work printer
    hardware.printers = {
      ensurePrinters = [
          {
              name = "EPSON Meteory Office";
              location = "Network";
              deviceUri = "dnssd://EPSON%20WF-2930%20Series._ipp._tcp.local/?uuid=cfe92100-67c4-11d4-a45f-f8255101cf90";
              model = "everywhere";  # Uses driverless IPP Everywhere
          }
      ];
      ensureDefaultPrinter = "EPSON_WF_2930_Series";
    };
}