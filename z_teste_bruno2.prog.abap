REPORT z_teste_bruno2.


**************************
* DEMIS
**************************



**********************************************************************
*     TIPOS                                                          *
**********************************************************************
TYPES: BEGIN OF ty_materiais,
         matnr TYPE mara-matnr,
         ersda TYPE mara-ersda,
         ernam TYPE mara-ernam,
       END OF ty_materiais.

TYPES: BEGIN OF ty_linha,
         matnr(30) TYPE c,
         maktx(40) TYPE c,
         ersda(30) TYPE c,
         dia(30)   TYPE c,
         ernam(30) TYPE c,
       END OF  ty_linha.

TYPES: BEGIN OF ty_desc,
         matnr TYPE makt-matnr,
         maktx TYPE makt-maktx,
       END OF ty_desc.

TYPES: BEGIN OF ty_saida,
         matnr TYPE makt-matnr,
         maktx TYPE makt-maktx,
         ersda TYPE mara-ersda,
         dia   TYPE char20,
         ernam TYPE mara-ernam,
       END OF ty_saida.

**********************************************************************
*     TABELAS INTERNAS                                               *
**********************************************************************
DATA: t_materiais TYPE TABLE OF ty_materiais,
      t_desc      TYPE TABLE OF ty_desc,
      t_saida     TYPE TABLE OF ty_saida,
      t_day_atrib TYPE TABLE OF casdayattr.


**********************************************************************
*     WORK AREA                                                      *
**********************************************************************
DATA : wa_materiais TYPE ty_materiais,
       wa_linha     TYPE ty_linha,
       wa_desc      TYPE ty_desc,
       wa_saida     TYPE ty_saida,
       wa_day_atrib TYPE casdayattr.

**********************************************************************
*     TELA DE SELEÇÃO                                                *
**********************************************************************

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME.
SELECT-OPTIONS:  s_matnr FOR wa_materiais-matnr.

SELECTION-SCREEN END OF BLOCK b1.

**********************************************************************
*     PROCESSAMENTO PRINCIPAL                                        *
**********************************************************************

START-OF-SELECTION.

* seleçao na tabela mara

  PERFORM f_seleciona_dados.

  PERFORM f_manipula_dados.

  IF t_saida[] IS NOT INITIAL.

    PERFORM f_imprimir_dados.

    CALL FUNCTION 'GUI_DOWNLOAD'
      EXPORTING
        filename                = 'C:\TESTE.TXT'
      TABLES
        data_tab                = t_saida
      EXCEPTIONS
        file_write_error        = 1
        no_batch                = 2
        gui_refuse_filetransfer = 3
        invalid_type            = 4
        no_authority            = 5
        unknown_error           = 6
        header_not_allowed      = 7
        separator_not_allowed   = 8
        filesize_not_allowed    = 9
        header_too_long         = 10
        dp_error_create         = 11
        dp_error_send           = 12
        dp_error_write          = 13
        unknown_dp_error        = 14
        access_denied           = 15
        dp_out_of_memory        = 16
        disk_full               = 17
        dp_timeout              = 18
        file_not_found          = 19
        dataprovider_exception  = 20
        control_flush_error     = 21
        OTHERS                  = 22.

    IF sy-subrc <> 0.

    ENDIF.


  ENDIF.


*&---------------------------------------------------------------------*
*&      Form  f_imprimir_dados
*&---------------------------------------------------------------------*
*       Imprimir dados selecionados
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_imprimir_dados .

  WRITE:    text-001 TO wa_linha-matnr,    "numero do material
            text-004 TO wa_linha-maktx,    "decriçao
            text-002 TO wa_linha-ersda,    "data de criaçao
            text-005 TO wa_linha-dia,
            text-003 TO wa_linha-ernam.    "usuario
  WRITE: wa_linha.

  SKIP.

  LOOP AT t_saida INTO wa_saida.

    WRITE:  wa_saida-matnr TO wa_linha-matnr,
            wa_saida-maktx TO wa_linha-maktx,
            wa_saida-ersda TO wa_linha-ersda,
            wa_saida-dia   TO wa_linha-dia,
            wa_saida-ernam TO wa_linha-ernam.
    WRITE: / wa_linha.

  ENDLOOP.



ENDFORM.                    " f_imprimir_dados
*&---------------------------------------------------------------------*
*&      Form  f_seleciona_dados
*&---------------------------------------------------------------------*
*       Seleciona dados para o relatorio
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_seleciona_dados .

  SELECT matnr ersda ernam
    FROM mara
    INTO TABLE t_materiais
    WHERE matnr IN s_matnr.

  IF sy-subrc = 0.

    SELECT matnr maktx
      FROM makt
      INTO TABLE t_desc
      FOR ALL ENTRIES IN t_materiais
      WHERE matnr = t_materiais-matnr AND
            spras = sy-langu.

    IF sy-subrc = 0.

    ENDIF.



  ENDIF.

ENDFORM.                    " f_seleciona_dados
*&---------------------------------------------------------------------*
*&      Form  f_manipula_dados
*&---------------------------------------------------------------------*
*       Monta a tabela de saida
*----------------------------------------------------------------------*

FORM f_manipula_dados .


  SORT t_desc BY matnr.

  LOOP AT t_materiais INTO wa_materiais.
    READ TABLE t_desc INTO wa_desc
      WITH KEY matnr = wa_materiais-matnr
      BINARY SEARCH.
    IF sy-subrc = 0.
      wa_saida-matnr = wa_materiais-matnr.
      wa_saida-maktx = wa_desc-maktx.
      wa_saida-ersda = wa_materiais-ersda.

      CALL FUNCTION 'DAY_ATTRIBUTES_GET'
        EXPORTING
          date_from                  = wa_materiais-ersda
          date_to                    = wa_materiais-ersda
        TABLES
          day_attributes             = t_day_atrib
        EXCEPTIONS
          factory_calendar_not_found = 1
          holiday_calendar_not_found = 2
          date_has_invalid_format    = 3
          date_inconsistency         = 4
          OTHERS                     = 5.

      IF sy-subrc = 0.

        READ TABLE t_day_atrib INTO wa_day_atrib INDEX 1.

        IF sy-subrc = 0.

          wa_saida-dia = wa_day_atrib-weekday_l.


        ENDIF.

        REFRESH t_day_atrib.

        wa_saida-ernam = wa_materiais-ernam.

        APPEND wa_saida TO t_saida.
        CLEAR wa_saida.



      ENDIF.
      CLEAR: wa_desc,
             wa_materiais.
    ENDIF.
  ENDLOOP.


ENDFORM.                    " f_manipula_dados
