#Include "Protheus.ch"
#INCLUDE 'FWMVCDEF.CH'
#Include 'Set.CH'

//---------------------------------------------------------------------
/*/{Protheus.doc} LbPedBlq
@Sample         :   U_LbPedBlq()

@description	:   Rotina responsavel por montar a janela de consulta Pedidos x Bloqueados.
	
                    Estrutura de interface: 
                    Dialog	-> TPanel01 -> Campos/Botões Filtro.   
                            -> TPanel02 -> Grid Browse com a listagem dos pedidos.

@Param		    :   Null
@Return 	    :   Null

@Author		lucas.Brustolin
@Since		05/06/2019	
@Version	12.1.17
/*/
//---------------------------------------------------------------------
User Function LbPedBlq()

Local aArea			:= GetArea()
Local oLayer		:= Nil
Local aSize			:= {}
//------------------------
Static 	cTitulo		:= "Pedidos x Bloqueios"
//------------------------
Private oDlgTela	:= Nil
Private oBrowse		:= NIL
Private dDatDe		:= CtoD("  /  /    ")
Private dDatAte		:= CtoD("  /  /    ")
Private oCbxFiltro	:= Nil
Private cFiltroSel	:= ""

//-- Definicoes da Janela
aSize	:= FWGetDialogSize( oMainWnd )

oDlgtela := MsDialog():New( aSize[1], aSize[2], aSize[3], aSize[4], cTitulo,,,, nOr( WS_VISIBLE, WS_POPUP ),,,,, .T.,,,, .F. ) 

oLayer := FWLayer():New()
oLayer:Init(oDlgTela,.F.,.T.)

//-- DIVISOR DE TELA SUPEIROR [ FILTRO ]
oLayer:AddLine("LINESUP", 25 )
oLayer:AddCollumn("BOX01", 100,, "LINESUP" )
oLayer:AddWindow("BOX01", "PANEL01", "Filtros", 100, .F.,,, "LINESUP" ) //"Filtros"

//-- DIVISOR DE TELA INFERIOR [ GRID ]
oLayer:AddLine("LINEINF", 75 )
oLayer:AddCollumn( "BOX02", 100,, "LINEINF" )
oLayer:AddWindow( "BOX02", "PANEL02", "Pedidos x Bloqueios"	, 100, .F.,,, "LINEINF" ) //"Pedidos x Bloqueio"

//-- ALOCA CADA COMPONENTE EM SEU RESPECTIVO BOX ( TPANEL )
FPanel01( oLayer:GetWinPanel( "BOX01", "PANEL01", "LINESUP" ) ) //Contrução do Painel de Filtros
FPanel02( oLayer:GetWinPanel( "BOX02", "PANEL02", "LINEINF" ) ) //Contrução do Painel Pedidos x Bloqueios


oDlgtela:Activate()

RestArea(aArea)

Return 

//---------------------------------------------------------------------
/*/{Protheus.doc} FPanel01
@Sample	        :   FPanel01()
@description    :   Cria a parte superior da janela "Filtros" e aloca ao painel 01.
	
@Param		    :   oPanel - Painel para alocar os componentes de filtro.
@Return 	    :   Null

@Author		lucas.Brustolin
@Since		05/06/2019	
@Version	12.1.17
/*/
//--------------------------------------------------------------------- 
Static Function FPanel01( oPanel )


Local bFiltrar	:=	Nil

//-- Inclui a borda pora apresentacao dos componentes em tela
TGroup():New( 005, 005, (oPanel:nHeight/2) - 005, (oPanel:nWidth/2) - 010 , "Filtros", oPanel,,, .T. ) //"Filtros"

//-- Inclui legendas dos campos
TSay():New( 020, 010, { || "Data De" }, oPanel,,,,,, .T.,,, 110, 010 ) //"Data De "
TSay():New( 020, 130, { || "Data Até"}, oPanel,,,,,, .T.,,, 110, 010 ) //"Data Até"

//-- Inclui os campos 
@030,010 MSGET dDatDe  	PICTURE "@D" SIZE 110, 010 OF oPanel PIXEL HASBUTTON
@030,130 MSGET dDatAte 	PICTURE "@D" SIZE 110, 010 OF oPanel PIXEL HASBUTTON

//-- Inclui combo com as opções de filtro
oCbxFiltro := TCOMBOBOX():Create(oPanel)
oCbxFiltro:cName 		:= "oCbxFiltro"
oCbxFiltro:cCaption 	:= "Filtro" 
oCbxFiltro:nLeft 		:= 505
oCbxFiltro:nTop 		:= 059
oCbxFiltro:nWidth 		:= 200
oCbxFiltro:nHeight 		:= 024
oCbxFiltro:lShowHint 	:= .F.
oCbxFiltro:lReadOnly 	:= .F.
oCbxFiltro:Align 		:= 0
oCbxFiltro:cVariable 	:= "cFiltroSel"
oCbxFiltro:bSetGet 		:= {|u| If(PCount()>0,cFiltroSel:=u,cFiltroSel) }
oCbxFiltro:aItems 		:= {"0=Todos","1=Bloqueio por Estoque", "2=Pedido Excluido","3=Romaneio Canc.\Excluido"}
oCbxFiltro:nAt 			:= 0                                                 

//Inclui botao filtrar -
bFiltrar := { || ExecFil("Aplicando Filtros") } 
TButton():New( 028,370, "Filtrar", oPanel, bFiltrar, 050, 013,,,, .T. ) //"Filtrar"

Return()

//---------------------------------------------------------------------
/*/{Protheus.doc} FPanel02
@Sample	        :   FPanel02()
@description	:   Cria a parte inferior da janela "Grid Browse" e aloca ao painel 02.

@Param		    :   oPanel
@Return 	    :   Null

@Author		lucas.Brustolin
@Since		05/06/2019	
@Version	12.1.17
/*/
//--------------------------------------------------------------------- 
Static Function FPanel02( oPanel,lAllQry )

Local cAliasQry	:= GetNextAlias() 
Local bVisual	:= Nil
Local aIndex	:= {}
Local aSeek 	:= {} 
Local cRetChave	:= ""
Local cQuery 	:= ""
Local nTpQry	:= 0

Default lAllQry	:= .T. // Carrega todos os bloqueios

// Aplica as definicoes para um Browse de tabela temporaria
oBrowse := FWFormBrowse():New()
oBrowse:SetDescription(cTitulo)
oBrowse:SetTemporary(.T.)
oBrowse:SetAlias(cAliasQry)
oBrowse:SetDataQuery()

If lAllQry
	cQuery := ""
	//-- Unifica todas as querys de bloqueio em uma unica (Union All) 
	For nTpQry := 1 To 3
		cQuery += GetQuery(nTpQry)

		If nTpQry < 3
			cQuery += CRLF
			cQuery += " UNION ALL  "
		Else
			cQuery += " ORDER BY C5_NUM "	
		EndIf 
	Next

	oBrowse:SetQuery(cQuery)
Else
	oBrowse:SetQuery(GetQuery())
EndIf 

oBrowse:SetOwner(oPanel)
oBrowse:SetDoubleClick({|| cRetChave := (oBrowse:Alias())->C5_NUM, oDlgTela:End()})
oBrowse:SetColumns(GetColumns(cAliasQry))
oBrowse:DisableDetails()

// ---------------------------------------------+
//  Faz o inserção dos botoes para o browse     |
// ---------------------------------------------+
oBrowse:AddButton( OemTOAnsi("Fechar")		    , {|| oDlgTela:End() } 	,, 2 ) //"Fechar"
bVisual	:= {|| U_LbExecPed( (oBrowse:Alias())->C5_NUM, MODEL_OPERATION_VIEW ) }
oBrowse:AddButton( OemTOAnsi("Visualizar")		, bVisual 				,, 2 ) //"Visualizar pedido de venda"
oBrowse:AddButton( OemTOAnsi("Legenda")			, {|| LegendBrw() } 	,, 2 ) //"Legenda"
oBrowse:AddButton( OemTOAnsi("Quem Deletou?")	, {|| PesqUsrDel(oBrowse:Alias()) } 	,, 2 ) //"Quem Deletou?"

// ------------------------------------------------------+
//  Cria Indices para obter a busca por pedido e Cliente |
// ------------------------------------------------------+
Aadd( aIndex, "C5_NUM" )
Aadd( aSeek, { "Pedido", { {"","C",TamSx3('C5_NUM')[1],0,"Pedido","@!"}  },1  } ) 

Aadd( aIndex, "C5_REFEREN" )
Aadd( aSeek, { "Referencia", { {"","C",TamSx3('C5_REFEREN')[1],0,"Referencia","@!"}  },2  } ) 

Aadd( aIndex, "C5_CLIENTE+C5_LOJACLI" )
Aadd( aSeek, { "Cliente+Loja" , {	{"","C",TamSx3('C5_CLIENTE')[1],0,"Cliente"	,"@!"} ,;
									{"","C",TamSx3('C5_LOJACLI')[1],0,"Loja"	,"@!"} },3  } ) 

Aadd( aIndex, "STATUS" )
Aadd( aSeek, { "Status", { {"","C",01,0,"Status","@!"}  },4  } ) 

oBrowse:SetQueryIndex(aIndex)
oBrowse:SetSeek(,aSeek)

//-------------------------
// Ativa exibição do browse 
oBrowse:Activate()

Return()

//---------------------------------------------------------------------
/*/{Protheus.doc} GetQuery
@Sample	        :   Retorna consulta sql de pedidos x bloqueios 
@description    :   Monta consulta sql para buscar os pedidos que possuem bloqueios. 
@Param		    :   nTipo = 1 Query para buscar os pedidos bloqueados por estoque
                    nTipo = 2 Query para buscar os pedidos excluidos por usuario
                    nTipo = 3 Query para buscar os pedidos com romaneio cancelado
@Return 	    :   cQuery

@Author		lucas.Brustolin
@Since		05/06/2019	
@Version	12.1.17
/*/
//--------------------------------------------------------------------- 
Static Function GetQuery(nTipo)

Local cQuery 	:= ""
Local cCampo 	:= ""
Local lInsOrder	:= .T.

Default nTipo	:= 1

//-- Aplica regra ao obter a selecao do filtro
If ValType(cFiltroSel) = "C"
	If Val(cFiltroSel) == 0 //"0=Todos"
		lInsOrder := .F.
	Else
		// "1=Bloqueio por Estoque", "2=Romaneio Cancelado", "3=Pedido Excluido"
		nTipo := Val(cFiltroSel)
	EndIf 
EndIf 

cCampo	:=	" C5_FILIAL"		
cCampo	+=	" ,C5_NUM"	 
cCampo	+=	" ,C5_REFEREN" 
cCampo	+=	" ,C5_TIPO"	 
cCampo	+=	" ,C5_NATUREZ" 	
cCampo	+=	" ,C5_CLIENTE" 	
cCampo	+=	" ,C5_LOJAENT" 	
cCampo	+=	" ,C5_LOJACLI"
cCampo	+=	" ,C5_EMISSAO"  	
cCampo	+=	" ,C5_TIPPED"  
cCampo	+=	" ,C5_TIPOCLI" 	
cCampo	+=	" ,C5_USERLGA"
cCampo	+=	" ,C5.R_E_C_N_O_ RECNO "


Do Case 

	// ----------------------------------------+
	// Query de pedidos bloqueados por estoque |
	// ----------------------------------------+
	Case nTipo = 1

	
		cQuery +=	" SELECT '1' STATUS, "+ cCampo +" FROM "+ RetSqlName('SC5') +"  C5 (NOLOCK) " 
		cQuery +=	" 	WHERE   C5_FILIAL   = '"+xFilial('SC5') + "'"
		cQuery +=	" 		AND C5_NUM      IN (    SELECT DISTINCT  C9.C9_PEDIDO  FROM "+ RetSqlName('SC9') + " C9 (NOLOCK) " 
		cQuery +=	" 						            WHERE	C9_FILIAL       = '"+xFilial('SC9') + "' "
		cQuery +=	" 						            AND     C9_BLEST        IN ('02','03') "  
		cQuery +=	" 						            AND     C9.D_E_L_E_T_   = '' ) "
		cQuery +=	" 		AND C5.D_E_L_E_T_ = ''"
		If !Empty(dDatDe) .Or. !Empty(dDatAte)
			cQuery +=	" 	AND C5_EMISSAO BETWEEN '"+Dtos(dDatDe)+"' AND '"+DTos(dDatAte)+"' " 
		EndIf 
		If lInsOrder
			cQuery +=	" ORDER BY C5.C5_NUM "
		EndIf 
	// ----------------------------------------+
	// Query de pedidos que foram Excluidos		|
	// ----------------------------------------+
	Case nTipo = 2

		cQuery +=	" SELECT '2' STATUS, "+ cCampo +" FROM "+ RetSqlName('SC5') +"  C5 (NOLOCK) " 
		cQuery +=	" 	WHERE C5_FILIAL = '"+xFilial('SC5') + "'"
		cQuery +=	" 		AND C5_NUM IN ( SELECT DISTINCT  C9.C9_PEDIDO  FROM "+ RetSqlName('SC9') + " C9 (NOLOCK) " 
		cQuery +=	" 						    WHERE	C9_FILIAL       = '"+xFilial('SC9') + "' "
		cQuery +=	" 						    AND     C9_BLEST        IN ('02','03') "  
		cQuery +=	" 						    AND     C9.D_E_L_E_T_   = '' ) "
		cQuery +=	" 		AND C5.D_E_L_E_T_ = '*'"
		If !Empty(dDatDe) .Or. !Empty(dDatAte)
			cQuery +=	" 	AND C5_EMISSAO BETWEEN '"+Dtos(dDatDe)+"' AND '"+DTos(dDatAte)+"' " 
		EndIf 
		If lInsOrder
			cQuery +=	" ORDER BY C5.C5_NUM "
		EndIf 

	// -----------------------------------------------+
	// Query de pedidos Romaneios Cancelados ou Excluido |
	// -----------------------------------------------+
	Case nTipo = 3

		cQuery +=	" SELECT DISTINCT '3' STATUS, "+ cCampo +" FROM  "+ RetSqlName('SC5') +"  C5 (NOLOCK) " 
		cQuery +=	" 	INNER JOIN "+ RetSqlName('PB9') +"  PB9 (NOLOCK)  "
		cQuery +=	" 		ON (	PB9_FILIAL		= C5.C5_FILIAL	"
		cQuery +=	" 				AND PB9_PEDIDO	= C5.C5_NUM    	"
		cQuery +=	" 				AND PB9_MOTCAN	<> '' "
		cQuery +=	"			) " 
		cQuery +=	" WHERE C5.C5_FILIAL = '"+xFilial('SC5')+"' ""
		If !Empty(dDatDe) .Or. !Empty(dDatAte)
			cQuery +=	" 	AND C5.C5_EMISSAO BETWEEN '"+Dtos(dDatDe)+"' AND '"+DTos(dDatAte)+"' "  
		EndIf 
		
		cQuery +=	" 	AND C5.D_E_L_E_T_  = ' ' "
		If lInsOrder
			cQuery +=	" ORDER BY C5.C5_NUM "
		EndIf 


EndCase  

Return(cQuery)

//---------------------------------------------------------------------
/*/{Protheus.doc} ExecFil
@Sample	UpdateBrw()
	Executa rotina de atualização do browse com opção de tela de processamento. 
@Param		cMsgRun

@Author		lucas.Brustolin
@Since		05/06/2019	
@Version	12.1.17
/*/
//--------------------------------------------------------------------- 
Static Function ExecFil(cMsgRun)

Default cMsgRun	:=  "" 

If !Empty(cMsgRun)
	FWMsgRun( ,{|| UpdateBrw() },"Aguarde",cMsgRun)	
Else
	CursorWait()
	UpdateBrw()
	CursorArrow()
EndIf


//---------------------------------------------------------------------
/*/{Protheus.doc} UpdateBrw
@Sample	UpdateBrw()
	Faz atualização dos dados que estao no browse (REFRESH) 
@Param		Null

@Author		lucas.Brustolin
@Since		05/06/2019	
@Version	12.1.17
/*/
//--------------------------------------------------------------------- 
Static Function UpdateBrw()

oBrowse:Data():DeActivate()
oBrowse:SetQuery( GetQuery() )
oBrowse:Data():Activate()
oBrowse:UpdateBrowse(.T.)
oBrowse:GoBottom()
oBrowse:GoTo(1,.T.)
oBrowse:Refresh(.T.)

Return()


//---------------------------------------------------------------------
/*/{Protheus.doc} GetColumns
@Sample	GetColumns()
	Rotina responsavel por montar a estrutura das colunas do Browse.
	
@Param		cAlias
@Return 	aColumns Estrutura de colunas do Browse - FwFormBrowse
@Author		lucas.Brustolin
@Since		05/06/2019	
@Version	12.1.17
/*/
//--------------------------------------------------------------------- 
Static Function GetColumns(cAlias)

Local aArea	:= GetArea()
Local cCampo	:= ""
Local aCampos	:= {}
Local aColumns	:= {}
Local nX		:= 0
Local nLinha	:= 0
Local cIniBrw	:= ""
Local aCpoQry	:= {}


aCampos := {'C5_FILIAL'	, ;	
			'C5_NUM'	, ; 
			'C5_REFEREN', ; 
			'C5_TIPO'	, ; 	
			'C5_CLIENTE', ; 	
			'C5_LOJAENT', ; 	
			'C5_LOJACLI', ;
			'C5_EMISSAO', ;  	
			'C5_TIPPED' , ; 
			'C5_TIPOCLI', ; 	
			'C5_USERLGA', ;
			'RECNO' }
			
DbSelectArea("SX3")
DbSetOrder(2)//X3_CAMPO

AAdd(aColumns,FWBrwColumn():New())
nLinha := Len(aColumns)
aColumns[nLinha]:SetData(&(  "{ || IIF( (cAlias)->STATUS =='1','BR_LARANJA', IIF( (cAlias)->STATUS == '2','BR_VERMELHO','BR_PINK')) } "))
aColumns[nLinha]:SetTitle("")
aColumns[nLinha]:SetType("C")
aColumns[nLinha]:SetPicture("@BMP")
aColumns[nLinha]:SetSize(1)
aColumns[nLinha]:SetDecimal(0)
aColumns[nLinha]:SetDoubleClick({|| LegendBrw() })
aColumns[nLinha]:SetImage(.T.)


For nX := 1 To Len(aCampos)
	If SX3->(DbSeek(AllTrim(aCampos[nX])))
		If (X3USO(SX3->X3_USADO) .AND. SX3->X3_BROWSE == "S" .AND. SX3->X3_TIPO <> "M") .OR. SX3->X3_CAMPO = "C5_FILIAL"
			AAdd(aColumns,FWBrwColumn():New())
			nLinha	:= Len(aColumns)
			cCampo 	:= AllTrim(SX3->X3_CAMPO)
			cIniBrw := AllTrim(SX3->X3_INIBRW)
			aColumns[nLinha]:SetType(SX3->X3_TIPO)
			If SX3->X3_CONTEXT <> "V"
				aAdd(aCpoQry,cCampo)
				If SX3->X3_TIPO = "D"
					aColumns[nLinha]:SetData( &("{|| sTod("  + "('"+cAlias+"')->" + cCampo + ") }") )
				ElseIf !Empty(X3CBox())
					aColumns[nLinha]:SetData( &("{|| X3Combo('" +  cCampo + "',('"+cAlias+"')->" + cCampo + ") }") )
				Else
					aColumns[nLinha]:SetData( &("{|| " + "('"+cAlias+"')->" + cCampo + " }") )
				EndIf
			Else
				aColumns[nLinha]:SetData( &("{|| U_LbRetBrw(" + "'"+cIniBrw+"','"+cAlias+"'" + ") }") )
			EndIf
			aColumns[nLinha]:SetTitle(X3Titulo())
			aColumns[nLinha]:SetSize(SX3->X3_TAMANHO)
			aColumns[nLinha]:SetDecimal(SX3->X3_DECIMAL)

			// Adiciona na memoria o conteudo da celula ao realizar o duplo click
			If aCampos[nX] $ "C5_NUM|C5_REFEREN|C5_CLIENTE|"
				aColumns[nLinha]:SetDoubleClick( &("{|| CopytoClipboard(" + "('"+cAlias+"')->" + cCampo + ") }") )
			EndIf 

		EndIf
	ElseIf aCampos[nX] == "RECNO"
		
		cCampo := "RECNO"
		AAdd(aColumns,FWBrwColumn():New())
		nLinha := Len(aColumns)
		aColumns[nLinha]:SetData( &("{|| " + "('"+cAlias+"')->" + cCampo + " }") )
		aColumns[nLinha]:SetTitle("RECNO")
		aColumns[nLinha]:SetType("C")
		aColumns[nLinha]:SetPicture("9999999")
		aColumns[nLinha]:SetSize(7)
		aColumns[nLinha]:SetDecimal(0)
		aColumns[nLinha]:SetDoubleClick( &("{|| CopytoClipboard(" + "('"+cAlias+"')->" + cCampo + ") }") )

	EndIf
Next nX


RestArea(aArea)

Return(aColumns)


//---------------------------------------------------------------------
/*/{Protheus.doc} 
@Sample	
	Executa funcao definida no inicializador padrao do browse X3_INIBRW
@Param		cIniBrw -> 
			cAlias	->

@Return 	cRetorno
@Author		lucas.Brustolin
@Since		05/06/2019	
@Version	12.1.17
/*/
//--------------------------------------------------------------------- 
User Function LbRetBrw(cIniBrw,cAlias)
Local cRetorno := ""

DbSelectArea(cAlias)
DbSetOrder(1)//

If DbSeek(xFilial(cAlias)+(cAlias)->C5_NUM)
	cRetorno := &(cIniBrw)
EndIf    

Return(cRetorno)  

//---------------------------------------------------------------------
/*/{Protheus.doc} LbExecPed
@Sample	U_LbExecPed('BXG010',MODEL_OPERATION_VIEW)
Abre tela padrao do pedido de venda na operação informada via parametro

@Param		cPedido,	->	Pedido no qual desejar realizar manutenção.
			nOperation	->	Operacao a ser executada.

@Author		lucas.Brustolin
@Since		05/06/2019	
@Version	12.1.17
/*/
//--------------------------------------------------------------------- 
User Function LbExecPed(cPedido,nOperation)

Local aArea 		:= GetArea()  
Local bExec			:= Nil
Local cMsgRun		:= ""
Local lRet			:= .T.
//------------------
Private Inclui    	:= .F. 
Private Altera    	:= .T. 
Private nOpca     	:= 1   					// Obrigatoriamente passo a variavel nOpca com o conteudo 1
Private cCadastro 	:= "Pedido de Vendas"	// Obrigatoriamente preciso definir com private a variável cCadastro
Private aRotina		:= {} 					// Obrigatoriamente preciso definir a variavel aRotina como private 
//------------------
Default cPedido		:= ""
Default nOperation	:= MODEL_OPERATION_INSERT


// --------------------------------+
//	FAZ A VALIDAÇÃO DAS OPERACOES  |	
// --------------------------------+	
If Empty(cPedido) .And. nOperation <> MODEL_OPERATION_INSERT
	FwAlertHelp("A operacao exige que o pedido de venda seja informado!","Revise o parametro pedido.") 	
	lRet := .F.
ElseIf !Empty(cPedido)
	//-- Busca pelo pedido informado
	If nOperation <> MODEL_OPERATION_INSERT
		DbSelectArea("SC5") //Abro a tabela SC5
		SC5->(DbSetOrder(1)) //Ordeno no índice 1
		If !( SC5->(DbSeek(xFilial("SC5")+cPedido))  )//Localizo o meu pedido
			FwAlertHelp("O pedido selecionado foi excluido da base de dados!","Pedido: " + cPedido ) 
			lRet := .F.
		EndIf
	EndIf 
EndIf 

If lRet 
	// ---------------------------------------------------+
	//	EXECUTA FUNCAO PADRAO p/ CADA OPERACAO DO MATA410 |	
	// ---------------------------------------------------+	
	Do Case 
		Case nOperation = MODEL_OPERATION_VIEW
			cMsgRun := "Abertura do pedido de venda"
			bExec := {|| MatA410(Nil, Nil, Nil, Nil, "A410Visual") }
		Case nOperation = MODEL_OPERATION_INSERT
			bExec := {|| MatA410(Nil, Nil, Nil, Nil, "A410Inclui") } 
			cMsgRun := "Abertura para inclusao do pedido de venda"
		Case nOperation = MODEL_OPERATION_UPDATE
			bExec := {|| MatA410(Nil, Nil, Nil, Nil, "A410Altera") }
			cMsgRun := "Abertura para alteracao do pedido de venda"
		Case nOperation = MODEL_OPERATION_DELETE
			bExec := {|| MatA410(Nil, Nil, Nil, Nil, "A410Deleta") }
			cMsgRun := "Abertura para exclusao do pedido de venda"
		OTHERWISE
			lRet := .F.
	EndCase 

	If ( lRet )
		FWMsgRun( , bExec,"Aguarde",cMsgRun)	
	EndIf 

EndIf 

RestArea(aArea) //restauro a area anterior.

Return(lRet)


//---------------------------------------------------------------------
/*/{Protheus.doc} LegendBrw
@Sample	LegendBrw()
	Monta interface com as legenda do browse
@Param		Null
@Return 	Null
@Author		lucas.Brustolin
@Since		05/06/2019	
@Version	12.1.17
/*/
//--------------------------------------------------------------------- 
Static Function LegendBrw()

Local oLegenda  :=  FWLegend():New()


oLegenda:Add("","BR_LARANJA"	,"Pedido bloqueado por Estoque")
oLegenda:Add("","BR_VERMELHO" 	,"Pedido Excluido")
oLegenda:Add("","BR_PINK"		,"Pedido com Romaneio Cancelado ou Excluido")

oLegenda:Activate()
oLegenda:View()
oLegenda:DeActivate()

Return Nil


//---------------------------------------------------------------------
/*/{Protheus.doc} PesqUsrDel
@Sample	PesqUsrDel()
	Apresenta um alerta com o nome e data do responsavel pela alteracao
@Param		cAliasQry - Alias temporario do browse
@Return 	Null
@Author		lucas.Brustolin
@Since		13/06/2019	
@Version	12.1.17
/*/
//--------------------------------------------------------------------- 
Static Function PesqUsrDel(cAliasQry)

Local aArea		:= GetArea()
Local cNome		:= ""
Local dData		:= CTOD("  /  /    ")
Local cDatDel 	:= ""
Local cRomaneio	:= ""
Local cMsg 		:= ""

Default cAliasQry := ""

If Select(cAliasQry) > 0

	// CONSIDERO OS REGISTROS DELETADOS AO REALIZAR O SEEK
	Set(_SET_DELETED, .F.)

	If (cAliasQry)->STATUS == "2"

		DbSelectArea("SC5") // Pedido de venda
		SC5->( DbGoTo((cAliasQry)->RECNO) )

		cNome 	:= FwLeUserLg("C5_USERLGA",1)
		dData	:= FwLeUserLg("C5_USERLGA",2)
		cDatDel	:= IIF(ValType(dData) == "D", DTOS(dData),"")

		If Empty(cNome) 
			cNome := "ADMINISTRADOR"
		EndIf 

		cMsg	:= "O usuario " + cNome + " realizou a exclusao do pedido. " + CRLF 
		cMsg	+= "Data de exclusao: " + cDatDel
	
	ElseIf (cAliasQry)->STATUS == "3"
		
		DbSelectArea("PB9")		// Romaneio
		PB9->( DbSetOrder(2) ) 	// PB9_FILIAL + PB9_PEDIDO + PB9_ITEM  
		
		If PB9->( DbSeek(xFilial("PB9") + (cAliasQry)->C5_NUM) )
			cRomaneio := PB9->PB9_PEDIDO

			//-- Procura entre os itens do romaeio o que possui a informacao user\data deletado
			// Pois alguns dos itens nao estao vindo preenchidos
			While PB9->( !Eof() .And. PB9->PB9_PEDIDO == cRomaneio)

				If !Empty(PB9->PB9_USUDEL)
					cNome 	:= AllTrim(PB9->PB9_USUDEL)
					cDatDel := AllTrim(PB9->PB9_DATDEL)
					Exit
				EndIf 
				PB9->( DbSkip() )
			EndDo 
		EndIf 

		If Empty(cNome) 
			cNome := "ADMINISTRADOR"
		EndIf 

		cMsg	:= "O usuario " + cNome + " realizou a exclusao do pedido. " + CRLF 
		cMsg	+= "Data\Hora de exclusao: " + cDatDel

	Else 

		cMsg	:= "Este registro nao foi deletado!"

	EndIf 

	// VOLTO A IGNORAR OS REGISTROS DELETADOS AO REALIZAR O SEEK
	Set(_SET_DELETED, .T.)

	MsgInfo("<font face='Lucida Sans'><b>"+ cMsg  +"</b>","Quem Deletou?"	)

EndIf 

RestArea(aArea)

Return()

