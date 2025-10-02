unit Unit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Edit, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs, FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.FMXUI.Wait,
  FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, Data.DB,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, FMX.Controls.Presentation;

type
  TLoginForm = class(TForm)
    edtKorisnickoIme: TEdit;
    edtLozinka: TEdit;
    btnLogin: TButton;
    FDConnection1: TFDConnection; // Tvoja komponenta, podešena u IDE-u
    FDQuery1: TFDQuery;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    procedure btnLoginClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    // NEMA VIŠE InicijalizujBazu, KreirajTabele, UbaciTestPodatke
  public
    { Public declarations }
  end;

var
  LoginForm: TLoginForm;

implementation

uses Unit2,Unit3,Unit4;

{$R *.fmx}

procedure TLoginForm.FormCreate(Sender: TObject);
begin
  // Ostavljamo prazno. Ne radimo ništa sa konekcijom,
  // jer je ona već podešena na komponenti.
  // Možeš i obrisati celu FormCreate proceduru ako ti ne treba za nešto drugo.
end;

procedure TLoginForm.btnLoginClick(Sender: TObject);
var
  UlogovaniID: Integer;
begin
  try
    // Povezujemo se na bazu koristeći podešavanja sa komponente
    FDConnection1.Connected := True;

    // Obavezno dodeljujemo konekciju i upitu na ovoj formi
    FDQuery1.Connection := FDConnection1;
    FDQuery1.SQL.Text := 'SELECT KorisnikID FROM Korisnici WHERE KorisnickoIme = :KI AND Lozinka = :LO';
    FDQuery1.ParamByName('KI').AsString := edtKorisnickoIme.Text;
    FDQuery1.ParamByName('LO').AsString := edtLozinka.Text;
    FDQuery1.Open;

    if not FDQuery1.IsEmpty then
    begin
      UlogovaniID := FDQuery1.FieldByName('KorisnikID').AsInteger;

      // PRIMOPREDAJA - ostaje ista, savršeno radi
      GlavnaForma.UlogovaniKorisnikID := UlogovaniID;
      GlavnaForma.FDConnection1 := Self.FDConnection1;

      Self.Hide;
      GlavnaForma.Show;
    end
    else
    begin
      ShowMessage('Pogrešno korisničko ime ili lozinka!');
    end;
  finally
    if FDQuery1.Active then FDQuery1.Close;
    // Opciono, možemo zatvoriti konekciju, ali nije obavezno
    // if FDConnection1.Connected then FDConnection1.Connected := False;
  end;
end;

end.
