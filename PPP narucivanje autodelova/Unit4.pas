unit Unit4;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  FMX.ListView, Data.DB, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Comp.Client, FireDAC.Comp.DataSet,
  FMX.Layouts, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
  FireDAC.DApt, FMX.Controls.Presentation;

type
  TPregledPorudzbinaForm = class(TForm)
    lvPorudzbine: TListView;
    FDQueryPregled: TFDQuery;
    Panel1: TPanel;
    btnNazad: TButton;
    btnOsvezi: TButton;
    btnPreuzmi: TButton;
    btnPrikaziStavke: TButton;
    btnNazadNaListu: TButton;
    btnUTransport: TButton;
    procedure FormShow(Sender: TObject);
    procedure btnNazadClick(Sender: TObject);
    procedure btnOsveziClick(Sender: TObject);
    procedure btnPreuzmiClick(Sender: TObject);
    procedure btnPrikaziStavkeClick(Sender: TObject);
    procedure btnNazadNaListuClick(Sender: TObject);
    procedure btnUTransportClick(Sender: TObject);
  private
    { Private declarations }
    FPrikazujemStavke: Boolean;
    FTrenutnaPorudzbinaID: Integer;
    procedure UcitajPodatke;
    procedure PrikaziStavkePorudzbine(PorudzbinaID: Integer);
    procedure PromeniStatus(PorudzbinaID: Integer; NoviStatus: string);
  public
    { Public declarations }
    FDConnection1: TFDConnection;
  end;

var
  PregledPorudzbinaForm: TPregledPorudzbinaForm;

implementation

uses Unit1;

{$R *.fmx}

procedure TPregledPorudzbinaForm.FormShow(Sender: TObject);
begin
  if Assigned(FDConnection1) then
  begin
    FDQueryPregled.Connection := FDConnection1;
    FPrikazujemStavke := False;
    btnNazadNaListu.Visible := False;
    UcitajPodatke;
  end
  else
  begin
    ShowMessage('Greška: Forma za pregled nije dobila konekciju!');
    Self.Close;
  end;
end;

procedure TPregledPorudzbinaForm.UcitajPodatke;
var
  ListItem: TListViewItem;
  PorudzbinaID: Integer;
  ItemTextObj: TListItemText;
  TempQuery: TFDQuery;
  StavkeText: string;
begin
  if not Assigned(FDConnection1) then Exit;

  FPrikazujemStavke := False;
  btnNazadNaListu.Visible := False;

  lvPorudzbine.BeginUpdate;
  try
    lvPorudzbine.Items.Clear;

    FDQueryPregled.SQL.Text :=
      'SELECT p.PorudzbinaID, p.NazivDobavljaca, p.UkupnaCena, ' +
      '       p.DatumPorudzbine, p.Status, k.KorisnickoIme ' +
      'FROM Porudzbine p ' +
      'LEFT JOIN Korisnici k ON p.KorisnikID = k.KorisnikID ' +
      'ORDER BY p.PorudzbinaID DESC';

    FDQueryPregled.Open;

    while not FDQueryPregled.Eof do
    begin
      ListItem := lvPorudzbine.Items.Add;
      PorudzbinaID := FDQueryPregled.FieldByName('PorudzbinaID').AsInteger;
      ListItem.Tag := PorudzbinaID;

      TempQuery := TFDQuery.Create(nil);
      try
        TempQuery.Connection := FDConnection1;
        TempQuery.SQL.Text :=
          'SELECT COUNT(*) AS BrojStavki FROM StavkePorudzbine WHERE PorudzbinaID = :ID';
        TempQuery.ParamByName('ID').AsInteger := PorudzbinaID;
        TempQuery.Open;
        StavkeText := TempQuery.FieldByName('BrojStavki').AsString + ' stavki';
        TempQuery.Close;
      finally
        TempQuery.Free;
      end;

      ListItem.Text := Format('Porudžbina #%d - %s - %s - %.2f RSD',
        [
          PorudzbinaID,
          FDQueryPregled.FieldByName('Status').AsString,
          FDQueryPregled.FieldByName('NazivDobavljaca').AsString,
          FDQueryPregled.FieldByName('UkupnaCena').AsFloat
        ]);

      ListItem.Detail := 'Naručeno: ' +
        FormatDateTime('dd.mm.yyyy HH:nn', FDQueryPregled.FieldByName('DatumPorudzbine').AsDateTime) +
        ' | ' + StavkeText;

      ItemTextObj := ListItem.Objects.FindObjectT<TListItemText>('text');
      if Assigned(ItemTextObj) then
      begin
        if FDQueryPregled.FieldByName('Status').AsString = 'Preuzeto' then
          ItemTextObj.TextColor := TAlphaColors.Green
        else if FDQueryPregled.FieldByName('Status').AsString = 'U transportu' then
          ItemTextObj.TextColor := TAlphaColors.Blue
        else
          ItemTextObj.TextColor := TAlphaColors.Orange;
      end;

      FDQueryPregled.Next;
    end;
  finally
    if FDQueryPregled.Active then FDQueryPregled.Close;
    lvPorudzbine.EndUpdate;
  end;
end;

procedure TPregledPorudzbinaForm.PrikaziStavkePorudzbine(PorudzbinaID: Integer);
var
  ListItem: TListViewItem;
  ItemTextObj: TListItemText;
begin
  if not Assigned(FDConnection1) then Exit;

  FPrikazujemStavke := True;
  FTrenutnaPorudzbinaID := PorudzbinaID;
  btnNazadNaListu.Visible := True;

  lvPorudzbine.BeginUpdate;
  try
    lvPorudzbine.Items.Clear;

    FDQueryPregled.SQL.Text :=
      'SELECT p.*, k.KorisnickoIme ' +
      'FROM Porudzbine p ' +
      'LEFT JOIN Korisnici k ON p.KorisnikID = k.KorisnikID ' +
      'WHERE p.PorudzbinaID = :ID';
    FDQueryPregled.ParamByName('ID').AsInteger := PorudzbinaID;
    FDQueryPregled.Open;

    if not FDQueryPregled.IsEmpty then
    begin
      ListItem := lvPorudzbine.Items.Add;
      ListItem.Tag := -1;
      ListItem.Text := Format('═══ Porudžbina #%d - %s ═══',
        [
          PorudzbinaID,
          FDQueryPregled.FieldByName('NazivDobavljaca').AsString
        ]);
      ListItem.Detail := Format('Status: %s | Datum: %s | Ukupno: %.2f RSD',
        [
          FDQueryPregled.FieldByName('Status').AsString,
          FormatDateTime('dd.mm.yyyy HH:nn', FDQueryPregled.FieldByName('DatumPorudzbine').AsDateTime),
          FDQueryPregled.FieldByName('UkupnaCena').AsFloat
        ]);

      ItemTextObj := ListItem.Objects.FindObjectT<TListItemText>('text');
      if Assigned(ItemTextObj) then
        ItemTextObj.TextColor := TAlphaColors.Navy;
    end;

    FDQueryPregled.Close;

    FDQueryPregled.SQL.Text :=
      'SELECT * FROM StavkePorudzbine WHERE PorudzbinaID = :ID ORDER BY StavkaID';
    FDQueryPregled.ParamByName('ID').AsInteger := PorudzbinaID;
    FDQueryPregled.Open;

    while not FDQueryPregled.Eof do
    begin
      ListItem := lvPorudzbine.Items.Add;
      ListItem.Tag := FDQueryPregled.FieldByName('StavkaID').AsInteger;

      ListItem.Text := Format('%s × %d kom',
        [
          FDQueryPregled.FieldByName('NazivDela').AsString,
          FDQueryPregled.FieldByName('Kolicina').AsInteger
        ]);

      ListItem.Detail := Format('Cena po kom: %.2f RSD | Ukupno: %.2f RSD',
        [
          FDQueryPregled.FieldByName('CenaPoKomadu').AsFloat,
          FDQueryPregled.FieldByName('UkupnaCenaStavke').AsFloat
        ]);

      FDQueryPregled.Next;
    end;

  finally
    if FDQueryPregled.Active then FDQueryPregled.Close;
    lvPorudzbine.EndUpdate;
  end;
end;

procedure TPregledPorudzbinaForm.PromeniStatus(PorudzbinaID: Integer; NoviStatus: string);
var
  TrenutniStatus: string;
begin
  try
    FDQueryPregled.SQL.Text := 'SELECT Status FROM Porudzbine WHERE PorudzbinaID = :ID';
    FDQueryPregled.ParamByName('ID').AsInteger := PorudzbinaID;
    FDQueryPregled.Open;

    if FDQueryPregled.IsEmpty then
    begin
      ShowMessage('Greška: Porudžbina nije pronađena.');
      FDQueryPregled.Close;
      Exit;
    end;

    TrenutniStatus := FDQueryPregled.FieldByName('Status').AsString;
    FDQueryPregled.Close;

    // Provera validnosti tranzicije statusa
    if NoviStatus = 'U transportu' then
    begin
      if TrenutniStatus = 'U transportu' then
      begin
        ShowMessage('Ova porudžbina je već u transportu.');
        Exit;
      end;
      if TrenutniStatus = 'Preuzeto' then
      begin
        ShowMessage('Ne možete vratiti preuzetu porudžbinu u transport.');
        Exit;
      end;
    end
    else if NoviStatus = 'Preuzeto' then
    begin
      if TrenutniStatus = 'Preuzeto' then
      begin
        ShowMessage('Ova porudžbina je već preuzeta.');
        Exit;
      end;
    end;

    // Ažuriranje statusa
    FDQueryPregled.SQL.Text :=
      'UPDATE Porudzbine SET Status = :Status WHERE PorudzbinaID = :ID';
    FDQueryPregled.ParamByName('Status').AsString := NoviStatus;
    FDQueryPregled.ParamByName('ID').AsInteger := PorudzbinaID;
    FDQueryPregled.ExecSQL;

    ShowMessage(Format('Porudžbina #%d je promenila status na: %s', [PorudzbinaID, NoviStatus]));

    if FPrikazujemStavke then
      PrikaziStavkePorudzbine(FTrenutnaPorudzbinaID)
    else
      UcitajPodatke;
  except
    on E: Exception do
      ShowMessage('Greška pri promeni statusa: ' + E.Message);
  end;
end;

procedure TPregledPorudzbinaForm.btnPrikaziStavkeClick(Sender: TObject);
begin
  if lvPorudzbine.Selected = nil then
  begin
    ShowMessage('Molimo vas, prvo izaberite porudžbinu sa liste.');
    Exit;
  end;

  if FPrikazujemStavke then
  begin
    ShowMessage('Već prikazujete stavke. Kliknite "Nazad na listu" prvo.');
    Exit;
  end;

  PrikaziStavkePorudzbine(lvPorudzbine.Selected.Tag);
end;

procedure TPregledPorudzbinaForm.btnNazadNaListuClick(Sender: TObject);
begin
  UcitajPodatke;
end;

procedure TPregledPorudzbinaForm.btnOsveziClick(Sender: TObject);
begin
  if FPrikazujemStavke then
    PrikaziStavkePorudzbine(FTrenutnaPorudzbinaID)
  else
    UcitajPodatke;
end;

procedure TPregledPorudzbinaForm.btnUTransportClick(Sender: TObject);
var
  SelektovaniID: Integer;
begin
  if FPrikazujemStavke then
  begin
    ShowMessage('Vratite se na listu porudžbina prvo.');
    Exit;
  end;

  if lvPorudzbine.Selected = nil then
  begin
    ShowMessage('Molimo vas, prvo izaberite porudžbinu sa liste.');
    Exit;
  end;

  SelektovaniID := lvPorudzbine.Selected.Tag;
  PromeniStatus(SelektovaniID, 'U transportu');
end;

procedure TPregledPorudzbinaForm.btnPreuzmiClick(Sender: TObject);
var
  SelektovaniID: Integer;
begin
  if FPrikazujemStavke then
  begin
    ShowMessage('Vratite se na listu porudžbina prvo.');
    Exit;
  end;

  if lvPorudzbine.Selected = nil then
  begin
    ShowMessage('Molimo vas, prvo izaberite porudžbinu sa liste.');
    Exit;
  end;

  SelektovaniID := lvPorudzbine.Selected.Tag;
  PromeniStatus(SelektovaniID, 'Preuzeto');
end;

procedure TPregledPorudzbinaForm.btnNazadClick(Sender: TObject);
begin
  Self.Close;
end;

end.
