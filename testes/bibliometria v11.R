#
# BIBLIOTECAS
#

#install.packages("bibliometrix")
#install.packages("shiny")
#install.packages("tm")
#install.packages("SnowballC")
#install.packages("wordcloud")

library("shiny")
library("bibliometrix")
library("tm")
library("SnowballC")
library("wordcloud")

#
# VARI?VEIS GLOBAIS
#

dados = data.frame()          # VARI?VEL QUE ARMAZENA O DATAFRAME PRINCIPAL CONSTRU?DO PELO BIBLIOMETRIX
analise_bibliometrica = ""    # VARI?VEL QUE ARMAZENA AN?LISE FEITA PELO BIBLIOMETRIX

#
# FUN??ES INICIAL E DE APOIO
#

# FORMATA N?MERO SIMPLES - XX.XXX
fns = function(n){ prettyNum(n,big.mark = ".", big.interval =  3,decimal.mark=",") }

# FORMATA N?MERO DECIMAL - XX.XXX,XX
fnd = function(n){ prettyNum(round(n,2), big.mark = ".", big.interval = 3, decimal.mark = ",", nsmall = 2) }

# TRANSFORMA O TEXTO DO ARQUIVO EM DATAFRAME E REALIZA AN?LISE
TransformaEmDataFrame = function(texto){
  dados <<- convert2df(texto, dbsource="isi", format="plaintext")
  analise_bibliometrica <<- biblioAnalysis(dados, sep = ";")
}

#
# FUN??ES PRINCIPAIS
#

# C?LCULA A QUANTIDADE DE PUBLICA??ES DO ARQUIVO
QuantidadePublicacoes = function(){ length(dados[[1]]) }

# C?LCULA O ?NDICE H E G
topindiceh = function(qtd=10){
  
  authors=gsub(","," ",names(analise_bibliometrica$Authors)[1:qtd])
  indices <- Hindex(dados, authors, sep = ";")
  ind = capture.output(indices$H)
  j=2
  i=1
  saida = ""
  txt = ind
  while(j <= length(txt)){
    tmp = strsplit(txt[[j]],"  ")
    k=1
    for(k in 1:length(tmp)){
      tmp2=c(tmp[[k]])
      tmp2 = tmp2 [! tmp2 %in% c("")]
      saida = paste(saida, "<tr><td>" ,tmp2[1], "</td><td align='right'>" ,tmp2[2], "</td>
                              <td align='right'>" ,tmp2[3], "</td><td align='right'>" , tmp2[4],  "</td></tr>")
      i=i+1
      k=k+1
    }
    j=j+1
  }
  saida
  
}

# C?LCULA O ?NDICE DE CRESCIMENTO ANUAL DOS ARTIGOS
IndiceCrescimentoAnual = function(){
  Y=data.frame(table(analise_bibliometrica$Years))
  names(Y)=c("Year   ", "Articles")
  print(Y,row.names=FALSE);cat("\n")
  ny=dim(Y)[1]
  GR=((Y[ny,2]/Y[1,2])^(1/(ny-1))-1)*100
  GR
}

# C?LCULA AS CITA??ES LOCAIS
localcitation = function(qtd=10){
  CR <- localCitations(dados, analise_bibliometrica, sep = ".  ")
  lc = capture.output(CR[1:qtd])
  j=2
  i=1
  saida = ""
  txt = lc
  while(j <= length(txt)){
    tmp = strsplit(txt[[j]],"   ")
    k=1
    for(k in length(tmp)){
      tmp2=c(tmp[[k]])
      tmp2 = tmp2 [! tmp2 %in% c("")]
      saida = paste(saida, "<tr><td>",i,"</td><td>" ,tmp2[1], "</td><td align='right'>" ,tmp2[2], "</td>
                    <td align='right'>" ,tmp2[3], "</td><td align='right'>" ,tmp2[4], "</td>
                    <td align='right'>" ,tmp2[5], "</td></tr>")
      i=i+1
      k=k+1
    }
    j=j+1
  }
  saida
}

# C?LCULA O INDICADOR - AUTOR DOMINANCE
AutorDominance = function(qtd_autores=10){
  DF <- dominance(analise_bibliometrica,qtd_autores )
  txt = capture.output(DF)
  saida = ""
  j=2
  i=1
  while(j <= length(txt)){
    tmp = strsplit(txt[[j]],"   ")
    k=2
    for(k in length(tmp))
    {
      tmp2=c(tmp[[k]])
      tmp2 = tmp2 [! tmp2 %in% c("")]
      
      saida = paste(saida, "<tr><td>",i,"</td><td>" ,tmp2[1], "</td><td align='right'>" ,tmp2[2], "</td>
                    <td align='right'>" ,tmp2[3], "</td><td align='right'>" ,tmp2[4], "</td>
                    <td align='right'>" ,tmp2[5], "</td><td align='right'>" ,tmp2[6], "</td></tr>")
      i=i+1
      k=k+1
    }
    j=j+1
  }
  saida
}

# C?LCULA OS AUTORES MAIS REFERENCIADOS
PublicacoesMaisReferenciadas = function (qtd=10){
  CR <- citations(dados, field = "article", sep = ".  ")
  publicacoes = capture.output(CR$Cited[2:qtd])
  i=1
  saida = ""
  j=2
  while(j <= length(publicacoes)){
    saida = paste(saida, "<tr><td>",i,"</td><td>" ,publicacoes[j], "</td><td>" ,publicacoes[j+1], "</td></tr>")
    j=j+2
    i=i+1
  }
  saida
}

# C?LCULA QUANTAS PALAVRAS EXISTEM EXCLUINDO AS REPETIDAS
QuantidadePalavrasChavesSemRepeticao = function(){
  pc = c()
  for(i in dados$ID){
    for(j in strsplit(i, ";")){
      pc = c(pc, trimws(j))
    }
  }
  length(unique(pc[!is.na(pc) & pc !=""]))
}

# C?LCULA A QUANTIDADE DE PALAVRAS CHAVES SEM REPETI??O - DE
QuantidadePalavrasChavesSemRepeticaoDE = function(){
  pc = c()
  for(i in dados$DE){
    for(j in strsplit(i, ";")){
      pc = c(pc, trimws(j))
    }
  }
  length(unique(pc[!is.na(pc) & pc !=""]))
}

# PALAVRAS CHAVES MAIS UTILIZADAS
PalavrasChavesMaisUtilizadas = function(n=10, ano = "Todos"){
  pc = c()
  analise = dados$DE
  if(ano != "Todos"){
    analise = dados$DE[dados$PY == ano]
  }
  if(n == "Todos"){
    n = length(dados$PY)
  }
  for(i in analise){
    for(j in strsplit(i, ";")){
        pc = c(pc, trimws(j))
    }
  }
  pc = pc[pc != ""]
  x= sort(table(pc), decreasing = TRUE)
  pc = names(x)
  valores = c(as.vector(x))
  saida = ""
  for(i in 1:n){
    if(!is.na(pc[i])){
        saida =   paste(saida,"<tr><td>",i,"</td><td>",pc[i],"</td>
                    <td align='right'>",fns(valores[i]),"</td></tr>")
    }
  }
  saida
}

# LISTA DOS ANOS DISPON?VEIS
VetorAnos = function(){
  x= sort(table (dados$PY), decreasing = TRUE)
  anos = c(names(x))
  anos = c("Todos", anos)
  as.list(sort(anos, decreasing = TRUE))
}

# LISTA DOS ANOS DISPON?VEIS - HTML
AnosPublicacao = function(){
  x= table (dados$PY)
  anos = c(names(x))
  valores = c(as.vector(x))
  saida = ""
  for(i in 1:length(anos)){
    saida =   paste(saida,"<tr><td>",anos[i],"</td><td align='right'>",fns(valores[i]),"</td></tr>")
  }
  saida
}

# FUN??ES DAS L?NGUAS DE PUBLICA??O
LinguasPublicacao = function(){
  x= sort(table (dados$LA), decreasing = TRUE)
  linguas = c(names(x))
  valores = c(as.vector(x))
  saida = ""
  for(i in 1:length(linguas)){
    saida =   paste(saida,"<tr><td>",linguas[i],"</td><td align='right'>",fns(valores[i]),"</td></tr>")
  }
  saida
}

# FUN??ES DOS TIPOS DE PUBLICA??ES
TiposPublicacao = function(){
  x= sort(table (dados$DT), decreasing = TRUE)
  linguas = c(names(x))
  valores = c(as.vector(x))
  saida = ""
  for(i in 1:length(linguas)){
    saida =   paste(saida,"<tr><td>",linguas[i],"</td><td align='right'>",fns(valores[i]),"</td></tr>")
  }
  saida
}

# LISTA PA?SES
listapaises2 = function(){
  dt=c()
  for( i in dados$RP){
    dt = c (dt , ( gsub("[.]", "", tail(strsplit(i,split=" ")[[1]],1)   ) ) )
  }
  ff= sort(table(dt), decreasing = TRUE)
  paises = names(ff)
  qtds = as.vector(ff)
  saida2 = ""
  for(i in 1:length(paises)){
    saida2 =   paste(saida2, "<tr><td>",paises[i],"</td><td align='right'>",fns(qtds[i]),"</td></tr>")
  }
  saida2
}

# LISTA PER?ODICOS QUE MAIS PUBLICAM
periodicostop = function(n,ano="Todos"){
  if(ano != "Todos") {periodicos = dados$PU[dados$PY==ano]}
  else {periodicos = dados$PU}
  t=sort(table(periodicos), decreasing = TRUE)
  nomes = names(t)
  qtds = as.vector(t)
  saida = ""
  for(i in 1:n){
    saida =   paste(saida,"<tr><td>",nomes[i],"</td><td align='right'>",fns(qtds[i]),"</td></tr>")
  }
  saida
}

# AUTORES MAIS CITADOS
autorestop = function(n,ano="Todos"){
  if(ano != "Todos") {autores = dados$AU[dados$PY==ano]}
  else {autores = dados$AU}
  vautores = c()
  for(i in autores){
    for(j in strsplit(i, ";"))   vautores = c(vautores, trimws(j))
  }
  t=sort(table(vautores), decreasing = TRUE)
  autores = names(t)
  qtds = as.vector(t)
  saida = ""
  for(i in 1:n){
    saida =   paste(saida,"<tr><td>",autores[i],"</td><td align='right'>",fns(qtds[i]),"</td></tr>")
  }
  saida
}

# QUANTIDADE DE AUTORES
QtdAutores = function(){
  autores = dados$AU
  vautores = c()
  for(i in autores){
    for(j in strsplit(i, ";"))   vautores = c(vautores, trimws(j))
  }
  length(unique(vautores[!is.na(vautores) & vautores != ""]))
}

# QUANTIDADE DE PUBLICA??O DE UM ?NICO AUTORE
QtdPublicacoesUmAutor = function(){
  autores = as.vector(dados$AU)
  autores  = autores[autores!= "[ANONYMOUS]"& !is.na(autores) & autores != ""]
  qtd = 0
  v =c()
  for(i in autores){
    v = c(v , (length(strsplit(i, ";")[[1]])))
  }  
  length(v[v==1])
}

# QUANTIDADE DE PUBLICA??ES MAIS DE UM AUTOR
QtdPublicacoesComMaisDeUmAutor = function(){
  autores = dados$AU
  qtd = 0
  for(i in autores){
    if(lengths(strsplit(i, ";")) >= 2)   qtd = qtd + 1
  }
  qtd
}

# QUANTIDADE DE PUBLICA??ES SEM AUTOR DEFINIDO
QtdPublicacoesSemAutor = function(){
  autores = as.vector(dados$AU)
  autores  = autores[autores== "[ANONYMOUS]" | is.na(autores) | autores == ""]
  qtd = 0
  v =c()
  for(i in autores){
    v = c(v , (length(strsplit(i, ";")[[1]])))
  }  
  length(v)
}

# M?DIA DE AUTOR POR PUBLICA??O
MediadeAutoresPorPublicacao = function(){
  QtdAutores()/QuantidadePublicacoes()
}

# C?LCULA LEI DE BRADFORD
leidebradford = function(){
  categorias = dados$SC
  vcategorias = c()
  for(i in categorias){
    for(j in strsplit(i, ";"))   vcategorias = c(vcategorias, trimws(j))
  }
  t=sort(table(vcategorias[vcategorias!=""]), decreasing = TRUE)
  categorias = sort(names(t))
  saida = "<tr><th >PU/SC</th><th>Total</th>"
  for(categoria in categorias){
    saida = paste(saida, "<th >",categoria,"</th>")
  }
  saida = paste(saida, "</tr>")
  editores = sort(unique(dados$PU), decreasing = FALSE )
  for(editor in editores){
    saida = paste(saida, "<tr><td>",editor,"</td>")
    z = 0
    tmp=""
    for(categoria in categorias){
      t = length (   dados$PU[dados$PU == editor & grepl(categoria, dados$SC) ]   )
      z=z+t
      tmp = paste(tmp, "<td><center>",t,"</center></td>")
    }
    
    saida = paste( saida, "<td><center>",z,"</center></td>",tmp,"</tr>")
  }
  saida
}

# M?DIA DE CITA??O POR ARTIGO
MediadeCitacoesporArtigo = function(){
   citacoes = dados$NR
   sum(as.numeric(citacoes))/QuantidadePublicacoes()
}

#
# SHINY CLIENTE
#

ui = fluidPage(
  titlePanel("An?lise Bibliom?trica"),
  tabsetPanel(
    tabPanel(
      "Dados",
      mainPanel(
          fileInput(
                    'file1', 
                    'Escolha o arquivo:',
                    accept=c('text/csv', 
                             'text/comma-separated-values,text/plain', 
                             '.csv')
          ),
          mainPanel(
            textOutput('paginainicial')
          )
      )
    ),
    tabPanel(
      "Resumo",
      htmlOutput("resumo")
    ),
    tabPanel(
      "Publica??es",
      tabsetPanel( 
        tabPanel("Mais Referenciados",  mainPanel(
          selectInput("qtd_top_pu", 
                      "Quantidade de Registros: ",
                      c("10" = 10,"20" = 20, "30" = 30,"40" = 40)),
          htmlOutput("publicacoes")
        )
        )
      )
    ),
    tabPanel(
      "Palavras Chaves",
      tabsetPanel( 
        tabPanel("Mais Utilizadas",  mainPanel(
                                      selectInput("qtd_top_pc", 
                                                  "Quantidade de Registros: ",
                                                  c("10" = 10,"20" = 20, "30" = 30,"40" = 40, "Todos")),
                                      selectInput("select_ano", "Escolha o ano: ", c()),
                                      htmlOutput("top10palavraschaves")
                                  )
                 ),
        tabPanel("KeyWord Coupling - Calor", plotOutput("plot_keyword_coupling")),
        tabPanel("Nuvem de Palavras (Lei de Zipf)",  mainPanel(
          plotOutput("mapapalavraschaves", width = "100%")
        )
        )
      )
    ),
    tabPanel(
      "Autores",
      tabsetPanel(
        tabPanel("Autores que mais publicaram (Lei de Lotka)", mainPanel(
          selectInput("qtd_top_autores", 
                      "Qtd. de Autores: ",
                      c("10 Mais" = 10,"20 Mais" = 20, "30 Mais" = 30,"40 Mais" = 40)),
          selectInput("select_ano_autor", "Escolha o ano: ", c()),
          htmlOutput("top10autores")
        )),
        tabPanel("Colabora??o Autores", plotOutput("plot_colaboration_autores")),
        tabPanel("?ndice-H", mainPanel(
          selectInput("qtd_top_h","Qtd. de Autores: ",c(10,20,  30, 40)), 
          htmlOutput("indiceh")
        )),
        tabPanel("Dominance", mainPanel(
          selectInput("qtd_top_dominance", "Qtd. de Autores: ",c(10,20,  30, 40)),
          htmlOutput("topdominance")
        ))
      )
    ),
    tabPanel(
      "Peri?dicos",
      tabsetPanel(
        tabPanel("Peri?dicos que mais publicaram", mainPanel(
          selectInput("qtd_top_periodicos", 
                      "Qtd. de periodicos: ",
                      c("10 Mais" = 10,"20 Mais" = 20, "30 Mais" = 30,"40 Mais" = 40)),
          selectInput("select_ano_periodico", "Escolha o ano: ", c()),
          htmlOutput("top10periodicos")
        )),
        tabPanel("Lei de Bradford", mainPanel(
          htmlOutput("leidebradford")
        ))
      )
    ),
    tabPanel(
      "Cita??es",
      tabsetPanel(
        tabPanel(
          "Local Citations",
          selectInput("qtd_top_local_citation", 
                      "Qtd. de Autores: ",
                      c("10 Mais" = 10,"20 Mais" = 20, "30 Mais" = 30,"40 Mais" = 40)),
          htmlOutput("localcitations")
        ),
        tabPanel("M?dia de Cita??o por Artigo", plotOutput("plot_media_citacao_por_artigo"))
      )
    )
  )
)

#
# SHINY SERVIDOR
#

server = function(input, output, session){
  
  output$paginainicial = renderText({
    inFile <- input$file1
    if (is.null(inFile))
      return(NULL)
    texto = readLines(inFile$datapath)
    TransformaEmDataFrame(texto)
    updateSelectInput(session, "select_ano", choices = VetorAnos())
    updateSelectInput(session, "select_ano_autor", choices = VetorAnos())
    updateSelectInput(session, "select_ano_periodico", choices = VetorAnos())
    updateSelectInput(session, "select_ano_pu", choices = VetorAnos())
    print(paste("Quantidade de Publica??es no arquivo: ", QuantidadePublicacoes()))
  })
  
  output$resumo = renderText({
    
    HTML(paste("
               <center>
                <p/>
                  <table width=\"90%\" border='1'><caption>An?lise Bibliom?trica B?sica<caption>
                    <tr>
                      <td width='70%'>Quantidade de Artigos:</td>
                      <td align='right'>",fns(nrow(dados)),"</td>
                    </tr>
                    <tr>
                      <td>Fontes de Informa??es (Revistas/Per?odicos):</td>
                      <td align='right'>",fns(length(unique(dados$SO))),"</td>
                    </tr>
                  </table>
                  <table width=\"90%\" border='1'><caption>Palavras Chaves</caption>
                    <tr>
                      <td width='70%'>Palavras Chaves sem Repeti??o (Thomson Reuters:ID):</td>
                      <td align='right'>",fns(QuantidadePalavrasChavesSemRepeticao()),"</td>
                    </tr>
                    <tr>
                      <td>M?dia (Thomson Reuters:ID):</td>
                      <td align='right'>",fnd(QuantidadePalavrasChavesSemRepeticao()/nrow(dados)),"</td>
                    </tr>
                    <tr>
                      <td>Palavras Chaves sem Repeti??o  (Autores:DE) :</td>
                      <td align='right'>",fns(QuantidadePalavrasChavesSemRepeticaoDE()),"</td>
                    </tr>
                    <tr>
                      <td>M?dia (Autores:DE) :</td>
                      <td align='right'>",fnd(QuantidadePalavrasChavesSemRepeticaoDE()/nrow(dados)),"</td>
                    </tr>
                  </table>
               
                  <table width=\"90%\" border='1'> <caption>Autores</caption>
                    <tr><td width='70%'>Quantidade de Autores:</td><td align='right'>",fns(QtdAutores()),"</td></tr>
                    <tr><td>Publica??es com um ?nico autor:</td><td align='right'>",fns(QtdPublicacoesUmAutor()),"</td></tr>
                    <tr><td>Publica??es com m?ltiplos autores:</td><td align='right'>",QtdPublicacoesComMaisDeUmAutor(),"</td></tr>
                    <tr><td>Publica??es An?nimas, NA, ou \"\":</td><td align='right'>",QtdPublicacoesSemAutor(),"</td></tr>
                    <tr><td>M?dia de Qtd. de Autor por Publica??o:</td><td align='right'>",fnd(MediadeAutoresPorPublicacao()),"</td></tr>
                    <tr><td>M?dia de Qtd. de Publica??es por Autor:</td><td align='right'>",fnd(1/MediadeAutoresPorPublicacao()),"</td></tr>
                    <tr><td>Autores (Apparences):</td><td align='right'>",fns(analise_bibliometrica$Apparences),"</td></tr>
                    <tr><td>M?dia de CoAutores por Artigo:</td><td align='right'>",fnd(mean(analise_bibliometrica$nAUperPaper)),"</td></tr>
                    <tr><td>?ndice de Colabora??o:</td><td align='right'>",fnd(analise_bibliometrica$AuMultiAuthoredArt/sum(analise_bibliometrica$nAUperPaper>1)),"</td></tr>
                  </table>
               
                  <table width=\"90%\" border='1'> <caption>Anos de Publica??o</caption>
                    <tr>
                      <th width='70%'><center>Ano</center></th>
                      <th><center>Qtd. Publica??es</center></th>
                    </tr>
                    ",AnosPublicacao(),"
                  </table>
               
                  <table width=\"90%\" border='1'> <caption>L?nguas</caption>
                    <tr>
                      <th width='70%'><center>L?ngua</center></th>
                      <th><center>Qtd. Publica??es</center></th>
                    </tr>
                    ",fns(LinguasPublicacao()),"
                  </table>
               
                  <table width=\"90%\" border='1'><caption>Outros</caption>
                    <tr>
                      <td width='70%'>M?dia de Cita??es por Artigo</td>
                      <td align='right'>",fnd(MediadeCitacoesporArtigo()),"</td>
                    </tr>
                    <tr>
                      <td width='70%'>?ndice de Crescimento Anual</td>
                      <td align='right'>",fnd(IndiceCrescimentoAnual()),"</td>
                    </tr>
                  </table>
               
                  <table width=\"90%\" border='1'> <caption>Tipos </caption>
                    <tr>
                      <th width='70%'><center>Tipo de Publica??o</center></th>
                      <th><center>Qtd. Publica??es</center></th>
                    </tr>
                    ",fns(TiposPublicacao()),
                  "</table>
               
                  <table width=\"90%\" border='1'> <caption>Pa?ses</caption>
                    <tr>
                      <th width='70%'><center>Pa?s</center></th>
                      <th><center>Qtd. de Publica??es</center></th>
                    </tr>
                    ",listapaises2(),
                  "</table>
               
                </center>
               "))
    
  })
  
  output$plot_keyword_coupling = renderPlot({
    NetMatrix <- biblioNetwork(dados, analysis = "coupling", network = "keywords", sep = ";")
    diag <- Matrix::diag 
    colSums <-Matrix::colSums
    ind=which(Matrix::colSums(NetMatrix)-Matrix::diag(NetMatrix)>0)
    NET=NetMatrix[ind,ind]
    n <- 10    
    NetDegree <- sort(diag(NET),decreasing=TRUE)[n]
    NET <- NET[diag(NET)>=NetDegree,diag(NET)>=NetDegree]
    diag(NET) <- 0
    n=30
    NETMAP=NetMatrix[ind,ind]
    MapDegree <- sort(diag(NETMAP),decreasing=TRUE)[n]
    NETMAP <- NETMAP[diag(NETMAP)>=MapDegree,diag(NETMAP)>=MapDegree]
    diag(NETMAP) <- 0
    H <- heatmap(max(NETMAP)-as.matrix(NETMAP),symm=T, cexRow=0.3,cexCol=0.3)
  })
  
  output$plot_colaboration_autores = renderPlot({
    NetMatrix = biblioNetwork(dados, analysis = "collaboration", network = "authors", sep = ". ")
    S <- couplingSimilarity(NetMatrix, type="jaccard")
    diag <- Matrix::diag
    MapDegree <- 3
    NETMAP <- S[diag(NetMatrix)>=MapDegree,diag(NetMatrix)>=MapDegree]
    diag(NETMAP) <- 0
    H <- heatmap(max(NETMAP)-as.matrix(NETMAP),symm=T, cexRow=0.3,cexCol=0.3)
  })
  
  output$plot_media_citacao_por_artigo = renderPlot({
    x = plot(x = analise_bibliometrica, k = 10, pause = FALSE)
  })
  
  output$indiceh = renderText({
    HTML(paste(
      "<table width=\"90%\" border='1'> 
        <caption>Autor - Local Citation:</caption>
        <tr>
          <th>n.</th>
          <th>Autor</th>
          <th>?ndice H</th>
          <th>?ndice G-M</th>
      </tr>
      ",topindiceh(as.numeric(input$qtd_top_h)),"</table>"
    )) 
  })
  
  output$localcitations = renderText({
    HTML(paste(
      "<table width=\"90%\" border='1'><caption>Autor - Local Citation:</caption>
      ",localcitation(as.numeric(input$qtd_top_local_citation)),"</table>"
    )) 
  })
  
  output$topdominance = renderText({
    HTML(paste(
      "<table width=\"90%\" border='1'><caption>Autor - Dominance:</caption>
        <tr>
          <th><center>n.</center></th>
          <th>Nome</th>
          <th>Fator Dominance</th>
          <th>Mult Autoral</th>
          <th>Primeiro Autor</th>
          <th>Rank por Artigo</th>
          <th>Rank por DF</th>
      </tr>
      ",AutorDominance(as.numeric(input$qtd_top_dominance)),"</table>"
    )) 
  })
  
  output$publicacoes=renderText({
    HTML(paste(
      "<table width=\"90%\" border='1'> <th><center>n.</center></th><th><center>Publica??o</center></th><th><center>Qtd. de Refer?ncias</center></th>
        <caption>Publicac?es mais Refer?nciadas:</caption>",PublicacoesMaisReferenciadas(input$qtd_top_pu),"</table>"))
  })
  
  output$acoplamento = renderText({
    HTML(paste(
      "<table width=\"90%\" border='1'>
          <caption>Acoplamento Bibliogr?fico<caption><tr>
          </tr>",acoplamento(),"</table>"
    ))
  })
  
  output$leidebradford = renderText({
    HTML(paste(
      "<table width=\"90%\" border='1'>
      <caption>Lei de Bradford<caption>",leidebradford(),"</table>"
    ))
  })
  
  output$top10periodicos= renderText({
    HTML(paste("<table width=\"90%\" border='1'><caption>Peri?dicos que mais publicam - TOP (",input$qtd_top_periodicos,")<caption>
                <tr>
                  <th><center>Palavra</center></th>
                  <th><center>Qtd.</center></th>
                </tr>",
                periodicostop(input$qtd_top_periodicos, input$select_ano_periodico),"</table>"))
  })
  
  output$top10autores = renderText({
    HTML(paste("<table width=\"90%\" border='1'><caption>Autores que mais publicam - TOP (",input$qtd_top_autores,")<caption>
                <tr>
                  <th><center>Palavra</center></th>
                  <th><center>Qtd.</center></th>
                </tr>
               ",autorestop(input$qtd_top_autores, input$select_ano_autor),"</table>"))
  })
  
  output$mapapalavraschaves = renderPlot({
    d = dados$DE[!is.na(dados$DE)]
    t = Corpus(VectorSource(d))
    t <- tm_map(t, content_transformer(tolower))
    t <- tm_map(t, removePunctuation)
    t <- tm_map(t, PlainTextDocument)
    t <- tm_map(t, removeWords, stopwords('english'))
    t <- tm_map(t, stemDocument)
    wordcloud(t, max.words = 100, random.order = FALSE, colors=brewer.pal(8, "Dark2"))
  })
  
  output$top10palavraschaves = renderText({
    HTML(paste("
               <center>
                  <table  width=\"90%\" border='1'><caption>Tipos </caption>
                    <tr>
                      <th width='10%'><center>n.</center></th> 
                      <th width='70%'><center>Palavra</center></th>
                      <th><center>Qtd. Cita??es</center></th>
                    </tr>",
                    PalavrasChavesMaisUtilizadas(input$qtd_top_pc, input$select_ano)
                    ,"</table>
                </center>
               "))
  })
}

#
# SHINY EXECUT?VEL
#

shinyApp(ui=ui, server=server)

