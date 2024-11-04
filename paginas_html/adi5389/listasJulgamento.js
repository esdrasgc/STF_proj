// https://portal.stf.jus.br/processos/listasJulgamento.js

function carregaSessaoVirtual(sessaoVirtual){
    $.LoadingOverlay('show');      
    $.ajax({
        type    : "GET",
        dataType: 'json',                
        url     : "https://sistemas.stf.jus.br/repgeral/votacao?sessaoVirtual="+ sessaoVirtual,
        cache   :  true,
        crossDomain: true,
        success : function(data){                    
            var html = "";
            for (i in data){
                if (data.length == 0){
                    html += '<div id="1020-'+ i +'" class="julgamento-item">' +
                            '   <div class="btn btn-lista">' +
                            '       <span class="listas'+ i +'" id="span'+ i +'"></span>' +
                            '       <span class="processo-detalhes-bold" id="cabecalhoVotacao'+ i +'">' + data[i].objetoIncidente.identificacaoCompleta + '</span><br>' +
                            '   </div>' +
                            '</div>';
                } else {
                    //--- SUSTENTAÇÕES ORAIS ---//
                    var htmlSustentacao = '';
                    if (data[i].sustentacoesOrais.length > 0){
                    htmlSustentacao +=  '<br><span class="processo-detalhes-bold">Sustentações Orais</span><br>'+
                                        '<table class="w-100" style="border: 1px solid #999;">'+
                                        '   <tr style="border-bottom: 1px solid #999;">'+
                                        '       <th style="padding:5px" width="5%"></th>'+
                                        '       <th style="padding:5px" width="45%">Advogado</th>'+
                                        '       <th style="padding:5px" width="45%">Parte</th>'+
                                        '   </tr>';
                        for (z in data[i].sustentacoesOrais){
                            htmlSustentacao+=   '<tr style="border-bottom: 1px solid #999;">'+
                                                '   <td style="padding:5px"><span><a href="'+ data[i].sustentacoesOrais[z].link +'"><i class="fas fa-headphones font-primary"></i></a></span></td>'+
                                                '   <td style="padding:5px"><span">'+ data[i].sustentacoesOrais[z].pessoaRepresentante.descricao +'</span></td>'+
                                                '   <td style="padding:5px"><span">'+ data[i].sustentacoesOrais[z].pessoaRepresentada.descricao +'</span></td>'+
                                                '</tr>';
                        }
                    htmlSustentacao += '</table>';

                    }
                    //------------------------------------------------------------------------------------//

                    //--- LISTAS DE JULGAMENTO ---//
                    for (j in data[i].listasJulgamento){

                        var htmlDecisao                = "";
                        var htmlRelatorio              = "";
                        var htmlVoto                   = "";
                        var htmlComplemento            = "";
                        var htmlVista                  = "";
                        var htmlDestaque               = "";
                        var htmlAcompanha              = "";
                        var htmlDiverge                = "";
                        var htmlAcompanhaDivergencia   = "";
                        var htmlAcompanhaRessalva      = "";
                        var htmlSuspeito               = "";
                        var htmlImpedido               = "";

                        //--- VERIFICA TEXTO CONCLUSÃO ---//
                        if (data[i].listasJulgamento[j].textoDecisao != ""){
                            htmlDecisao +=  '<tr>'+
                                            '   <td valign="top" width="150px"><span class="processo-detalhes-bold">Conclusão do voto: </span></td>' +
                                            '   <td><span class="desc-lista">'+ data[i].listasJulgamento[j].textoDecisao + '</span></td>' +
                                            '</tr>';
                        }
                        //------------------------------------------------------------------------------------//

                        //--- LISTAS DE JULGAMENTO ---//
                        var cabecalhoDescricao = removeHtml (data[i].listasJulgamento[j].cabecalho);

                        html +=
                        '<div class="m-b-16 d-block">'+
                        '   <a class="btn btn-link" role="button" data-bs-toggle="collapse" href="#listas'+ data[i].objetoIncidente.id + i + j +'" aria-expanded="false" aria-controls="listas'+ data[i].objetoIncidente.id + i + j +'">'+
                        '       <span class="processo-detalhes-bold m-l-32">Data de início do julgamento: '+ data[i].listasJulgamento[j].sessao.dataPrevistaInicio + '</span>'+
                        '   </a>'
                        '</div>';
                        //------------------------------------------------------------------------------------//

                        //--- CABEÇALHO ---//
                        html +=
                        '<div id="listas'+ data[i].objetoIncidente.id + i + j +'" class="resultado-lista__container collapse m-t-16 m-b-16" style="">' +
                            '<div class="col-12 card-resultado-lista bg-grey-light">'+
                                '<div class="titulo-lista m-16">' + cabecalhoDescricao + '</div>'+
                                '<div class="col-12 m-8" >'+
                                    '<table id="lista_cabecalho" class="lista_cabecalho">' +
                                        '<tr>' +
                                            '<td><span class="processo-detalhes-bold">Relator(a): </span></td>' +
                                            '<td><span class="desc-lista">' + data[i].listasJulgamento[j].ministroRelator.descricao + '</span></td>'+
                                        '</tr>' +
                                        '<tr>' +
                                            '<td><span class="processo-detalhes-bold">Órgão Julgador: </span></td>' +
                                            '<td><span class="desc-lista">' + data[i].listasJulgamento[j].sessao.colegiado.descricao + '</span></td>'+
                                        '</tr>' +
                                        '<tr>' +
                                            '<td><span class="processo-detalhes-bold">Lista: </span></td>' +
                                            '<td><span class="desc-lista">' + data[i].listasJulgamento[j].nomeLista + '</span></td>'+
                                        '</tr>' +
                                        '<tr>' +
                                            '<td><span class="processo-detalhes-bold">Processo: </span></td>' +
                                            '<td><span class="desc-lista">' + data[i].objetoIncidente.identificacao + '</span></td>'+
                                        '</tr>' +
                                        '<tr>' +
                                            '<td><span class="processo-detalhes-bold">Data início: </span></td>' +
                                            '<td><span class="desc-lista">' + data[i].listasJulgamento[j].sessao.dataInicio + '</span></td>'+
                                        '</tr>' +
                                        '<tr>' +
                                            '<td><span class="processo-detalhes-bold">Data prevista fim: </span></td>' +
                                            '<td><span class="desc-lista">' + data[i].listasJulgamento[j].sessao.dataPrevistaFim + '</span></td>'+
                                        '</tr>' +                                                    
                                    '</table>'+
                                    htmlSustentacao +
                                '</div>' +
                            '</div>';
                        //------------------------------------------------------------------------------------//

                        html+= '<div class="resultado-lista">';

                        //--- LINK RELATORIO ---//
                        if (data[i].listasJulgamento[j].relatorioRelator != ""){
                            htmlRelatorio +='<div class="col-md-3 processo-quadro" style="position:relative">' +
                                            '   <div class="numero">'+
                                            '       <a href="'+ data[i].listasJulgamento[j].relatorioRelator.link +'">'+
                                            '           <i class="far fa-file-alt font-primary"></i>' +
                                            '           <div class="rotulo">Relatório</div>'+
                                            '       </a>'+
                                            '   </div>'+
                                            '</div>';
                        }
                        //------------------------------------------------------------------------------------//

                        //--- LINK VOTO ---//
                        if (data[i].listasJulgamento[j].votoRelator.descricao == 'Voto'){
                            htmlVoto+=  '<div class="col-md-3 processo-quadro">'+
                                        '   <div class="numero">'+
                                        '       <a href="'+ data[i].listasJulgamento[j].votoRelator.link +'">'+
                                        '           <i class="fas fa-gavel font-verde"></i>'+                                                    
                                        '           <div class="rotulo">Voto</div>'+
                                        '       </a>'+
                                        '   </div>'+
                                        '</div>';
                        }
                        //------------------------------------------------------------------------------------//

                        //--- LINK COMPLEMENTO VOTO RELATOR ---//
                        if (data[i].listasJulgamento[j].complementoVotoRelator != ""){
                            htmlVoto+= '<div class="col-md-3 processo-quadro">'+
                                        '   <div class="numero">'+
                                        '       <a href="'+ data[i].listasJulgamento[j].complementoVotoRelator.link +'">'+
                                        '           <i class="fas fa-gavel font-verde"></i>'+                  
                                        '           <div class="rotulo">Complemento do Voto</div>'+
                                        '       </a>'+
                                        '   </div>'+
                                        '</div>';
                        }
                        //------------------------------------------------------------------------------------//

                        //--- CAIXA RELATOR DO PROCESSO---//
                        html+=  '<div class="col-12 card-resultado-lista m-t-8">'+
                                '   <div class="card-resultado-titulo">Relator</div>'+
                                '   <div class="d-flex flex-wrap justify-content-between">'+
                                '       <div class="col-md-3 lista-item julgador-voto '+ retornaCSS(JSON.parse(data[i].listasJulgamento[j].ministroRelator.codigo)) +'">&nbsp;'+
                                '           <span class="manifestacao-julgador">' + data[i].listasJulgamento[j].ministroRelator.descricao + '</span>'+
                                '       </div>'+
                                '       <div class="col-md-6 d-flex m-t-8 m-b-8">'+
                                            htmlRelatorio +
                                            htmlVoto +
                                            htmlComplemento +
                                '       </div>'+
                                '   </div>'+
                                '</div>';
                        //------------------------------------------------------------------------------------//

                        var contaVista                 = 0;
                        var contaDestaque              = 0;
                        var contaAcompanha             = 0;
                        var contaDiverge               = 0;
                        var contaAcompanhaDivergencia  = 0;
                        var contaAcompanhaRessalva     = 0;
                        var contaSuspeito              = 0;
                        var contaImpedido              = 0;

                        //--- VISTA ---//
                        if (!!data[i].listasJulgamento[j].ministroVista){
                            htmlVista+= '<div class="lista-item julgador-voto '+ retornaCSS(JSON.parse(data[i].listasJulgamento[j].ministroVista.codigo)) +'">&nbsp;'+
                                        '   <span class="manifestacao-julgador">' + data[i].listasJulgamento[j].ministroVista.descricao + '</span>'+
                                        '</div>';
                            if (!!data[i].listasJulgamento[j].ministroVista.textos) {
                                htmlVista +='<span class="">'+
                                            '   <a href="'+ data[i].listasJulgamento[j].ministroVista.textos[0].link +'" target="_blank">'+
                                            '       <i class="fas fa-gavel font-verde"></i>&nbsp;&nbsp;Voto'+
                                            '   </a>'+
                                            '</span>';

                            }
                            contaVista++;
                        }
                        //------------------------------------------------------------------------------------//

                        //--- DESTAQUE ---//
                        if (!!data[i].listasJulgamento[j].ministroDestaque){
                            htmlDestaque+=  '<div class="lista-item julgador-voto '+ retornaCSS(JSON.parse(data[i].listasJulgamento[j].ministroDestaque.codigo)) +'">&nbsp;'+
                                            '   <span class="manifestacao-julgador">' + data[i].listasJulgamento[j].ministroDestaque.descricao + '</span>'+
                                            '</div>';
                            contaDestaque++;
                        }
                        //------------------------------------------------------------------------------------//

                        

                        if (data[i].listasJulgamento[j].votos != ""){
                            for (k in data[i].listasJulgamento[j].votos){

                                //--- ACOMPANHA RELATOR ---//
                                if (data[i].listasJulgamento[j].votos[k].tipoVoto.codigo == 9){
                                    htmlAcompanha +='<div class="lista-item julgador-voto manifestacao-julgador-wrapper '+ retornaCSS(JSON.parse(data[i].listasJulgamento[j].votos[k].ministro.codigo)) +'">&nbsp;' +
                                                    '   <span class="manifestacao-julgador">' + data[i].listasJulgamento[j].votos[k].ministro.descricao;

                                //ACOMPANHA RELATOR - VOTO ANTECIPADO
                                    if (data[i].listasJulgamento[j].votos[k].votoAntecipado == "Sim"){
                                        htmlAcompanha += ' <span class="voto-antecipado"> - Voto antecipado</span></span>';
                                    } else{
                                        htmlAcompanha += '</span>';
                                    }
                                
                                //ACOMPANHA RELATOR - VOTO VOGAL
                                    if (data[i].listasJulgamento[j].votos[k].textos.length > 0) {
                                        for (l in data[i].listasJulgamento[j].votos[k].textos){
                                            htmlAcompanha +='<div style="margin-top: 15px;">'+
                                                            '   <span class="">'+
                                                            '       <a href="'+ data[i].listasJulgamento[j].votos[k].textos[l].link +'" target="_blank">'+
                                                            '           <i class="fas fa-gavel font-verde"></i>&nbsp;'+ 
                                                                        data[i].listasJulgamento[j].votos[k].textos[l].descricao +
                                                            '       </a>'+
                                                            '   </span>'+
                                                            '</div>';
                                        }
                                    }
                                
                                    htmlAcompanha +='</div>';
                                    contaAcompanha++;
                                }
                                //------------------------------------------------------------------------------------//


                                //--- DIVERGE RELATOR ---//
                                if (data[i].listasJulgamento[j].votos[k].tipoVoto.codigo == 7){
                                    htmlDiverge +=  '<div class="diverge-relator">'+
                                                    '   <div class="lista-item julgador-voto manifestacao-julgador-wrapper '+ retornaCSS(JSON.parse(data[i].listasJulgamento[j].votos[k].ministro.codigo)) +'">&nbsp;' +
                                                    '       <span class="manifestacao-julgador">' + data[i].listasJulgamento[j].votos[k].ministro.descricao;
                                                    
                                                    
                                    //DIVERGE RELATOR - VOTO ANTECIPADO
                                    if (data[i].listasJulgamento[j].votos[k].votoAntecipado == "Sim"){
                                        htmlDiverge += '<span class="voto-antecipado"> - Voto antecipado</span></span>';                                                    
                                    } else{
                                        htmlDiverge +='</span>';
                                    }
                                    
                                    htmlDiverge += '</span>';

                                    //DIVERGE RELATOR - VOTO VOGAL
                                    if (data[i].listasJulgamento[j].votos[k].textos.length > 0) {
                                        for (l in data[i].listasJulgamento[j].votos[k].textos){
                                            htmlDiverge +=  '<div style="margin-top: 15px;">'+
                                                            '   <span class="">'+
                                                            '       <a href="'+ data[i].listasJulgamento[j].votos[k].textos[l].link +'" target="_blank">'+
                                                            '           <i class="fas fa-gavel font-verde"></i>&nbsp;'+ 
                                                                        data[i].listasJulgamento[j].votos[k].textos[l].descricao +
                                                            '       </a>'+
                                                            '   </span>'+
                                                            '</div>';
                                        }
                                    }
                                    htmlDiverge += '</div></div>';
                                    contaDiverge++;
                                }
                                //------------------------------------------------------------------------------------//

                                //--- ACOMPANHA DIVERGENCIA ---//
                                if (data[i].listasJulgamento[j].votos[k].tipoVoto.codigo == 8){
                                    htmlAcompanhaDivergencia += '<div class="acompanha-divergencia-relator">'+
                                                                '   <div class="lista-item julgador-voto manifestacao-julgador-wrapper '+ retornaCSS(JSON.parse(data[i].listasJulgamento[j].votos[k].ministro.codigo)) +'">&nbsp;' +
                                                                '       <span class="manifestacao-julgador-linha1">' + data[i].listasJulgamento[j].votos[k].ministro.descricao;
                                    
                                    //ACOMPANHA DIVERGENCIA - VOTO ANTECIPADO
                                    if (data[i].listasJulgamento[j].votos[k].votoAntecipado == "Sim"){
                                        htmlAcompanhaDivergencia += '<span class="voto-antecipado"> - Voto antecipado</span></span>';
                                    } else{
                                        htmlAcompanhaDivergencia += '</span>';
                                    }                                                                    
                                                        
                                    htmlAcompanhaDivergencia +='<br><span class="manifestacao-julgador-linha2">Acompanha: ' + data[i].listasJulgamento[j].votos[k].acompanhandoMinistro.descricao + '</span>';
                                    
                                    
                                    //ACOMPANHA DIVERGENCIA - VOTO VOGAL
                                    if (data[i].listasJulgamento[j].votos[k].textos.length > 0) {
                                        for (l in data[i].listasJulgamento[j].votos[k].textos){
                                            htmlAcompanhaDivergencia += '<div style="margin-top: 15px;">'+
                                                                        '   <span class="">'+
                                                                        '       <a href="'+ data[i].listasJulgamento[j].votos[k].textos[l].link +'" target="_blank">'+
                                                                        '           <i class="fas fa-gavel font-verde"></i>&nbsp;'+ 
                                                                                    data[i].listasJulgamento[j].votos[k].textos[l].descricao +
                                                                        '       </a>'+
                                                                        '   </span>'+
                                                                        '</div>';
                                        }
                                    }
                                    htmlAcompanhaDivergencia += '</div></div>';
                                    contaDiverge++;
                                    contaAcompanhaDivergencia++;
                                }
                                //------------------------------------------------------------------------------------//

                                //--- ACOMPANHA RELATOR COM RESSALVAS---//
                                if (data[i].listasJulgamento[j].votos[k].tipoVoto.codigo == 10){
                                    htmlAcompanhaRessalva +='<div class="acompanha-ressalva">'+
                                                            '   <div class="lista-item julgador-voto manifestacao-julgador-wrapper '+ retornaCSS(JSON.parse(data[i].listasJulgamento[j].votos[k].ministro.codigo)) +'">&nbsp;' +
                                                            '       <span class="manifestacao-julgador">' + data[i].listasJulgamento[j].votos[k].ministro.descricao;

                                    if (data[i].listasJulgamento[j].votos[k].votoAntecipado == "Sim"){
                                        htmlAcompanhaRessalva +='<span class="voto-antecipado"> - Voto antecipado</span></span>';
                                    } else{
                                        htmlAcompanhaRessalva +='</span>';
                                    }
                                    
                                    if (data[i].listasJulgamento[j].votos[k].textos.length > 0) {
                                        for (l in data[i].listasJulgamento[j].votos[k].textos){
                                            htmlAcompanhaRessalva +='<div style="margin-top: 15px;">'+
                                                                    '   <span class="">'+
                                                                    '       <a href="'+ data[i].listasJulgamento[j].votos[k].textos[l].link +'" target="_blank">'+
                                                                    '           <i class="fas fa-gavel font-verde"></i>&nbsp;'+ 
                                                                                data[i].listasJulgamento[j].votos[k].textos[l].descricao +
                                                                    '       </a>'+
                                                                    '   </span>'+
                                                                    '</div>';
                                        }
                                    }
                                    htmlAcompanhaRessalva += '</div></div>';                                                
                                    contaAcompanhaRessalva++;
                                }
                                //------------------------------------------------------------------------------------//

                                //--- SUSPEITO ---//
                                if (data[i].listasJulgamento[j].votos[k].tipoVoto.codigo == 11){
                                    htmlSuspeito += '<div class="lista-item julgador-voto '+ retornaCSS(JSON.parse(data[i].listasJulgamento[j].votos[k].ministro.codigo)) +'">&nbsp;' +
                                                    '   <span class="manifestacao-julgador">' + data[i].listasJulgamento[j].votos[k].ministro.descricao + '</span>'+
                                                    '</div>';
                                    contaSuspeito++;
                                }
                                //------------------------------------------------------------------------------------//

                                //--- IMPEDIDO ---//
                                if (data[i].listasJulgamento[j].votos[k].tipoVoto.codigo == 3){
                                    htmlImpedido += '<div class="lista-item julgador-voto '+ retornaCSS(JSON.parse(data[i].listasJulgamento[j].votos[k].ministro.codigo)) +'">&nbsp;' +
                                                    '   <span class="manifestacao-julgador">' + data[i].listasJulgamento[j].votos[k].ministro.descricao + '</span>'+
                                                    '</div>';
                                    contaImpedido++;
                                }
                                //------------------------------------------------------------------------------------//
                            }
                        }

                        //--- CAIXA ACOMPANHA RELATOR ---//
                        if (contaAcompanha > 0){
                            
                            html+=  '<div class="col-sm-12 col-md-6 card-resultado-lista order-1 m-t-8" id="acompanha">' +
                                        '<div class="card-resultado-titulo font-verde">' +
                                            'Acompanho o Relator' +
                                        '</div>'+ htmlAcompanha+
                                    '</div>';
                        }
                        //------------------------------------------------------------------------------------//

                        //--- CAIXA ACOMPANHA RELATOR COM RESSALVA---//
                        if(contaAcompanhaRessalva > 0){

                            html+=  '<div class="col-sm-12 col-md-6 card-resultado-lista order-1 m-t-8" id="acompanha-ressalva">' +
                                        '<div class="card-resultado-titulo font-verde">' +
                                            'Acompanho o Relator com ressalvas' +
                                        '</div>'+ htmlAcompanhaRessalva+
                                    '</div>';
                        }
                        //------------------------------------------------------------------------------------//

                        //--- CAIXA DIVERGE RELATOR ---//
                        if (contaDiverge > 0){
                            html+=  '<div class="col-md-6 col-sm-12 card-resultado-lista order-2 dir m-t-8" id="diverge">' +
                                        '<div class="card-resultado-titulo font-danger">' +
                                            'Divirjo do Relator' +
                                        '</div>'+ htmlDiverge +
                                    '</div>';
                        }
                        //------------------------------------------------------------------------------------//


                        //--- CAIXA ACOMPANHA DIVERGENCIA ---//
                        if (contaAcompanhaDivergencia > 0){
                            html+=  '<div class="col-md-6 col-sm-12 card-resultado-lista order-3 dir m-t-8" id="diverge">' +
                                        '<div class="card-resultado-titulo font-danger">' +
                                            'Acompanho a divergência' +
                                        '</div>'+ htmlAcompanhaDivergencia +
                                    '</div>';
                        }
                        //------------------------------------------------------------------------------------//


                        //--- CAIXA SUSPEITO ---//
                        if (contaSuspeito > 0){
                            html+=  '<div class="col-12 card-resultado-lista order-4 m-t-8" id="suspeito">' +
                                        '<div class="card-resultado-titulo">' +
                                            'Suspeito' +
                                        '</div>'+ htmlSuspeito +
                                    '</div>';
                        }
                        //------------------------------------------------------------------------------------//

                        //--- CAIXA IMPEDIDO ---//
                        if (contaImpedido > 0){
                            html+=  '<div class="col-12 card-resultado-lista order-5 m-t-8" id="impedido">' +
                                        '<div class="card-resultado-titulo">' +
                                            'Impedido' +
                                        '</div>'+ htmlImpedido +
                                    '</div>';
                        }
                        //------------------------------------------------------------------------------------//

                        //--- CAIXA VISTA ---//
                        if (contaVista > 0){
                            html+=  '<div class="col-12 card-resultado-lista order-6 m-t-8" id="vista">' +
                                        '<div class="card-resultado-titulo">' +
                                            'Pedido de Vista' +
                                        '</div>'+ htmlVista +
                                    '</div>';
                        }
                        //------------------------------------------------------------------------------------//

                        //--- CAIXA DESTAQUE ---//
                        if (contaDestaque > 0){
                            html+=  '<div class="col-12 card-resultado-lista order-7 m-t-8" id="destaque">' +
                                        '<div class="card-resultado-titulo">' +
                                            'Destaque' +
                                        '</div>'+ htmlDestaque +
                                    '</div>';
                        }
                        //------------------------------------------------------------------------------------//

                    html+=  '</div>'+                                        
                            '</div>';
                    }
                }
            }
            var idJulgamento = 'listasJulgamento'+ data[i].objetoIncidente.id;
            $.LoadingOverlay('hide');  
            document.getElementById(idJulgamento).innerHTML = html;
        }
    })
}

function retornaCSS (codigoMinistro){
    switch(codigoMinistro){
        case 1:
            return 'presidente';
            break;
        case 28:
            return 'celso-mello';
            break;
        case 30:
            return 'marco-aurelio';
            break;
        case 36:
            return 'gilmar-mendes';
            break;
        case 41:
            return 'lewandowski';
            break;
        case 42:
            return 'carmen-lucia';
            break;
        case 44:
            return 'dias-toffoli';
            break;
        case 45:
            return 'luiz-fux';
            break;
        case 46:
            return 'rosa-weber';
            break;
        case 48:
            return 'roberto-barroso';
            break;
        case 49:
            return 'fachin';
            break;
        case 50:
            return 'alexandre-moraes';
            break;
        case 51:
            return 'nunes-marques';
            break;
        case 52:
            return 'andre-mendonca';
            break;
        case 53:
            return 'cristiano-zanin'
        case 54:
            return 'flavio-dino'
            break;
        default:
            return '';
    }
}

function removeHtml(stringHtml){
    var novaString  = stringHtml.replace(/(<span([^>]+)>)/ig,"");
    var novaString2 = novaString.replace(/(<font([^>]+)>)/ig,"");
    return novaString;
}