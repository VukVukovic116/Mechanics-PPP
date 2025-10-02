unit Unit2;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FMX.ListView, FireDAC.Stan.Param, FireDAC.DatS,
  FireDAC.DApt.Intf, FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Comp.Client;

type
  TGlavnaForma = class(TForm)
    btnKreirajPorudzbinu: TButton;
    btnPregledPorudzbina: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    lvAutodelovi: TListView;
    Label4: TLabel;
    btnOsveziListu: TButton;
    FDQuery1: TFDQuery;
    procedure btnKreirajPorudzbinuClick(Sender: TObject);
    procedure btnPregledPorudzbinaClick(Sender: TObject);
    procedure btnOsveziListuClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    procedure UcitajAutodelove;
  public
    { Public declarations }
    UlogovaniKorisnikID: Integer;
    FDConnection1: TFDConnection; // Konekcija se prima sa Login forme
  end;

var
  GlavnaForma: TGlavnaForma;

implementation

uses Unit3, Unit4; // Obavezno dodati uses za druge dve forme

{$R *.fmx}

procedure TGlavnaForma.FormShow(Sender: TObject);
begin
  // Kada se forma prikaže, odmah učitaj listu delova
  UcitajAutodelove;
end;

procedure TGlavnaForma.UcitajAutodelove;
var
  ListItem: TListViewItem;
begin
  if not Assigned(FDConnection1) then
  begin
    ShowMessage('Greška: Konekcija sa bazom nije uspostavljena!');
    Exit;
  end;

  Self.FDQuery1.Connection := Self.FDConnection1;

  lvAutodelovi.BeginUpdate;
  try
    lvAutodelovi.Items.Clear;

    // NOVI SQL upit koji prikazuje SVE delove
    Self.FDQuery1.SQL.Text :=
      'SELECT ' +
      '  a.DeoID, a.NazivDela, a.Cena, ' +
      '  GROUP_CONCAT(d.NazivDobavljaca, ", ") AS Dobavljaci ' + // Konkatenacija naziva dobavljača
      'FROM Autodelovi a ' +
      'JOIN Ponuda p ON a.DeoID = p.DeoID ' +
      'JOIN Dobavljaci d ON p.DobavljacID = d.DobavljacID ' +
      'GROUP BY a.DeoID ' +
      'ORDER BY a.NazivDela';

    Self.FDQuery1.Open;

    while not Self.FDQuery1.Eof do
    begin
      ListItem := lvAutodelovi.Items.Add;
      ListItem.Tag := Self.FDQuery1.FieldByName('DeoID').AsInteger;

      // GLAVNI TEKST: Naziv dela + cena
      ListItem.Text := Format('%s - %.2f RSD', [
        Self.FDQuery1.FieldByName('NazivDela').AsString,
        Self.FDQuery1.FieldByName('Cena').AsFloat
      ]);

      // DETALJNI TEKST: Spisak dobavljača koji nude taj deo
      ListItem.Detail := 'Dostupno kod: ' + Self.FDQuery1.FieldByName('Dobavljaci').AsString;

      Self.FDQuery1.Next;
    end;

  finally
    if Self.FDQuery1.Active then Self.FDQuery1.Close;
    lvAutodelovi.EndUpdate;
  end;
end;

procedure TGlavnaForma.btnKreirajPorudzbinuClick(Sender: TObject);
var
  Forma: TKreirajPorudzbinuForm;
begin
  Forma := TKreirajPorudzbinuForm.Create(nil);
  try
    // VAŽNO: Moramo proslediti konekciju i sledećoj formi!
    Forma.FDConnection1 := Self.FDConnection1;
    Forma.UlogovaniKorisnikID := Self.UlogovaniKorisnikID;
    Forma.ShowModal;
  finally
    Forma.Free;
  end;
end;

procedure TGlavnaForma.btnPregledPorudzbinaClick(Sender: TObject);
var
  Forma: TPregledPorudzbinaForm;
begin
  Forma := TPregledPorudzbinaForm.Create(nil);
  try
    // VAŽNO: I ovoj formi prosleđujemo istu konekciju!
    Forma.FDConnection1 := Self.FDConnection1;
    Forma.ShowModal;
  finally
    Forma.Free;
  end;
end;

procedure TGlavnaForma.btnOsveziListuClick(Sender: TObject);
begin
  UcitajAutodelove;
end;

end.
