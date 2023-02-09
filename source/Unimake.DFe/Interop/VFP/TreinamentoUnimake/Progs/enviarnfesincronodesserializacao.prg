* ---------------------------------------------------------------------------------
* Gerar XML da NFe e enviar no modo s�ncrono com desserializa��o do XML
*
* - Desserializa��o do XML da NFe/NFCe (J� tenho o arquivo do XML pronto e quero 
*   envi�-lo para SEFAZ sem precisar alimentar as propriedades da classe do XML)
* - Finalizando o envio da NFe/NFCe pela consulta situa��o (Enviei o XML da nota 
*   e n�o consegui pegar o retorno, como fa�o para finalizar a nota e 
*   gerar o XML de distribui��o?)
* - Enviei a nota e deu duplicidade, como fa�o para, somente, gerar o XML de 
*   distribui��o da NFe/NFCe?
* ---------------------------------------------------------------------------------
Function EnviarNfeSincronoDesserializacao()
   Local oConfig
   Local oEnviNFe, oNfe, oInfNFe, oIde, oEmit, oEnderEmit, oDest, oEnderDest
   Local oDet, oProd
   Local oImposto, oICMS, oICMSSN101, oPIS, oPISOutr, oCOFINS, oCOFINSOutr
   Local oTotal, oICMSTot, oImpostoDevol
   Local oTransp, oVol
   Local oCobr, oFat, oDup
   Local oPag, oDetPag
   Local oInfAdic, oInfRespTec
   Local oAutorizacao, oRetAutorizacao, oXmlRec, oConfigRec
   Local I, oErro, notaAssinada
   Local oXmlConsSitNFe, oConteudoNFe, oConteudoInfNFe, chaveNFe, oConfigConsSitNFe, oConsultaProtocolo

 * Criar configuracao basica para consumir o servico
   oConfig = CreateObject("Unimake.Business.DFe.Servicos.Configuracao")
   oConfig.TipoDfe = 0 && 0=nfe
   oConfig.TipoEmissao = 1 && 1=Normal
   oConfig.CertificadoArquivo = "C:\Projetos\certificados\UnimakePV.pfx"
   oConfig.CertificadoSenha = "12345678"
   
 * Criar a tag <enviNFe>
   oEnviNFe = CreateObject("Unimake.Business.DFe.Xml.NFe.EnviNFe")
   oEnviNFe.Versao = "4.00"
   oEnviNFe.IdLote = "000000000000001"
   oEnviNFe.IndSinc = 1 && 1=Sim 0=Nao
  
 * Criar a tag NFe e deserializar o XML j� gravado no HD para j� preencher o objeto para envio
   onfe = CreateObject("Unimake.Business.DFe.Xml.NFe.NFe")
   
   oEnviNFe.AddNFe(oNFe.LoadFromFile("D:\testenfe\41230206117473000150550010000590081999182930-nfe.xml")) 

 * Como deserializar partindo da string do XML
   && oEnviNFe.AddNFe(oNFe.LoadFromXML("asldkjaslkdjasldjaslkdjasldkjasldksjadas"))   
   
 * Recuperar a chave da NFe:
   oConteudoNFe = oEnviNFe.GetNFe(0)
   oConteudoInfNFe = oConteudoNFe.GetInfNFe(0)
   chaveNFe = oConteudoInfNFe.Chave
		 
   MessageBox("Chave da NFe:" + chaveNFe)

 * Consumir o serviço (Enviar NFE para SEFAZ)
   oAutorizacao = CreateObject("Unimake.Business.DFe.Servicos.NFe.Autorizacao")
   
 * Criar objeto para pegar excecao do lado do CSHARP
   oExceptionInterop = CreateObject("Unimake.Exceptions.ThrowHelper")   

   Try
      oAutorizacao.SetXMLConfiguracao(oEnviNFe, oConfig)      
	  
    * Pode-se gravar o conteudo do XML assinado na base de dados antes do envio, caso queira recuperar para futuro tratamento, isso da garantias
	  notaAssinada = oAutorizacao.GetConteudoNFeAssinada(0)
      MessageBox(notaAssinada) && Demonstrar o XML da nota assinada na tela

    * Gravar o XML assinado no HD, antes de enviar.
      DELETE FILE 'd:\testenfe\' + chaveNFe + '-nfe.xml'
	  StrToFile(notaAssinada, 'd:\testenfe\' + chaveNFe + '-nfe.xml', 0)  
  
    * Enviar a nota para SEFAZ
	  oAutorizacao.Executar(oEnviNFe, oConfig) 
	  
    * XML Retornado pela SEFAZ
      MessageBox(oAutorizacao.RetornoWSString)

    * Codigo de Status e Motivo
      MessageBox(AllTrim(Str(oAutorizacao.Result.CStat,5)) + " " +oAutorizacao.Result.XMotivo)
  
	  if oAutorizacao.Result.CStat == 104 && 104 = Lote Processado
         if oAutorizacao.Result.ProtNFe.InfProt.CStat == 100 && 100 = Autorizado o uso da NF-e
          * Gravar XML de distribuicao em uma pasta (NFe com o protocolo de autorizacao anexado)
            oAutorizacao.GravarXmlDistribuicao("d:\testenfe")
			
		  * Pegar a string do XML de distribui��o
            docProcNFe = oAutorizacao.GetNFeProcResults(chaveNFe)
			MessageBox(docProcNFe)

          * Como pegar o numero do protocolo de autorizacao para gravar na base
		    MessageBox(oAutorizacao.Result.ProtNFe.InfProt.NProt)
		 else
          * Rejeitada ou Denegada - Fazer devidos tratamentos		 
         ENDIF
      ELSE
         IF oAutorizacao.Result.CStat == 204 && Duplicidade da NFe
          * Finalizar a nota pela consulta situa��o
          * Configura��o M�nima
            oConfigConsSit = CreateObject("Unimake.Business.DFe.Servicos.Configuracao")
            oConfigConsSit.TipoDfe = 0 && 0=nfe
            oConfigConsSit.CertificadoSenha = "12345678"
            oConfigConsSit.CertificadoArquivo = "C:\Projetos\certificados\UnimakePV.pfx"          
         
          * Criar XML de consulta situa��o da NFe
            oConsSitNfe = CreateObject("Unimake.Business.DFe.Xml.NFe.ConsSitNfe")
            oConsSitNfe.Versao = "4.00"
            oConsSitNfe.TpAmb  = 2  && Homologa��o
            oConsSitNfe.ChNfe  = chaveNFe  && Chave da NFE 
            
          * Consumir o Servi�o de Consulta Situa��o da Nota
            oConsultaProtocolo = CREATEOBJECT("Unimake.Business.DFe.Servicos.NFe.ConsultaProtocolo")
            oConsultaProtocolo.Executar(oConsSitNFe, oConfigConsSit)
            
            MESSAGEBOX(oConsultaProtocolo.RetornoWSString)
            MESSAGEBOX(AllTrim(Str(oConsultaProtocolo.Result.CStat,5)) + " " + oConsultaProtocolo.Result.XMotivo)

            IF oConsultaProtocolo.Result.CStat == 100 && Nota Fiscal Autorizada
             * Alimentar a propriedade com o retorno da consulta
               oAutorizacao.AddRetConsSitNFes(oConsultaProtocolo.Result)
               
               oAutorizacao.GravarXmlDistribuicao("d:\testenfe")
               
             * Pegar a string do XML de distribui��o para gravar em uma base de dados, por exemplo.
               docProcNFe = oAutorizacao.GetNFeProcResults(chaveNFe)
    		   MessageBox(docProcNFe)
            ELSE
               MESSAGEBOX(oConsultaProtocolo.Result.CStat)
               MESSAGEBOX(oConsultaProtocolo.Result.XMotivo)         		 
            ENDIF          
            
         ENDIF
	  ENDIF	  
   
   Catch To oErro
    * Excecao do FOXPRO
	* Mais sobre excecao em FOXPRO
	* http://www.yaldex.com/fox_pro_tutorial/html/2344b71b-14c0-4125-b001-b5fbb7bd1f05.htm
	
	  MessageBox("FOXPRO - ErrorCode: " + ALLTRIM(STR(oErro.ErrorNo,10))+ " - Message: " + oErro.Message)
	  
    * Excecao do CSHARP
      MessageBox("CSHARP - ErrorCode: " + ALLTRIM(STR(oExceptionInterop.GetErrorCode(),20)) + " - Message: " + oExceptionInterop.GetMessage())
   EndTry
Return

