program Project1;

uses
  System.StartUpCopy,
  FMX.Forms,
  Unit1 in 'Unit1.pas' {LoginForm},
  Unit2 in 'Unit2.pas' {GlavnaForma},
  Unit3 in 'Unit3.pas' {KreirajPorudzbinuForm},
  Unit4 in 'Unit4.pas' {PregledPorudzbinaForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TLoginForm, LoginForm);
  Application.CreateForm(TGlavnaForma, GlavnaForma);
  Application.CreateForm(TKreirajPorudzbinuForm, KreirajPorudzbinuForm);
  Application.CreateForm(TPregledPorudzbinaForm, PregledPorudzbinaForm);
  Application.Run;
end.
