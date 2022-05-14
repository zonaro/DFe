* ---------------------------------------------------------------------------------
* Consumindo o servi�o de consulta status da NFe
* ---------------------------------------------------------------------------------

#IfNdef __XHARBOUR__
   #xcommand TRY => BEGIN SEQUENCE WITH {| oErr | Break( oErr ) }
   #xcommand CATCH [<!oErr!>] => RECOVER [USING <oErr>] <-oErr->
#endif

Function ConsultaStatusNfe()
   Local InicializarConfiguracao
   Local consStatServ, oErro, oExceptionInterop
   Local statusServico

 * Criar configura�ao b�sica para consumir o servi�o
   InicializarConfiguracao = CreateObject("Unimake.Business.DFe.Servicos.Configuracao")
   InicializarConfiguracao:TipoDfe = 0 // 0=nfe
   InicializarConfiguracao:Servico = 0 // 0=nfe status servi�o
   InicializarConfiguracao:CertificadoSenha = "12345678"
   InicializarConfiguracao:CertificadoArquivo = "C:\Projetos\certificados\UnimakePV.pfx"

 * Criar XML
   consStatServ = CreateObject("Unimake.Business.DFe.Xml.NFe.ConsStatServ")
   consStatServ:Versao = "4.00"
   consStatServ:TpAmb  = 2 // Homologa��o
   consStatServ:CUF    = 41 // PR

   //Criar objeto para pegar exce��o do CSHARP
   oExceptionInterop = CreateObject("Unimake.Exceptions.ThrowHelper")

   Try
    * Consumir o servi�o
      statusServico = CreateObject("Unimake.Business.DFe.Servicos.NFe.StatusServico")
      statusServico:Executar(consStatServ, InicializarConfiguracao)

      ? "XML Retornado pela SEFAZ"
      ? "========================"
      ? statusServico:RetornoWSString
      ?
      ? "Codigo de Status e Motivo"
      ? "========================="
      ? AllTrim(Str(statusServico:Result:CStat,5)),statusServico:Result:XMotivo
      ?

   Catch oErro
	  ? "ERRO"
	  ? "===="
	  ? "Falha ao tentar consultar o status do servico."
      ? oErro:Description
      ? oErro:Operation
	  
	  //Demonstrar a exce��o do CSHARP
	  ?
      ? "Excecao do CSHARP: ", oExceptionInterop:GetMessage()
      ?
   End	  

   Wait
Return