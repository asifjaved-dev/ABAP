FUNCTION zaj_hr_employee_create_basic.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(IS_BASIC) TYPE  ZAJ_HR_EMPLOYEE_BASIC OPTIONAL
*"  EXPORTING
*"     REFERENCE(EV_PERNR) TYPE  PERSNO
*"  TABLES
*"      ET_RETURN STRUCTURE  BAPIRETURN1
*"----------------------------------------------------------------------

  DATA: lt_proposed  TYPE STANDARD TABLE OF pprop,
        ls_proposed  TYPE pprop,
        lt_modkeys   TYPE STANDARD TABLE OF pskey,
        ls_modkey    TYPE pskey,
        ls_return    TYPE bapireturn,
        ls_return1   TYPE bapireturn1,
        ls_hr_return TYPE hrhrmm_msg,
        ls_1001      TYPE p1001,
        lt_1001      TYPE STANDARD TABLE OF p1001,
        ls_return3   TYPE bapireturn1,
        lv_begda     TYPE begda.

  lv_begda = sy-datum.

  " ---- IT0000 : Reason for Action ----
  ls_proposed-infty = '0000'.
  ls_proposed-fname = 'P0000-MASSG'. ls_proposed-fval = is_basic-massg. APPEND ls_proposed TO lt_proposed.

  " ---- IT0001 : Org Assignment fields not covered by direct params ----
  ls_proposed-infty = '0001'.
  ls_proposed-fname = 'P0001-BUKRS'. ls_proposed-fval = is_basic-bukrs. APPEND ls_proposed TO lt_proposed.
  ls_proposed-fname = 'P0001-GSBER'. ls_proposed-fval = is_basic-gsber. APPEND ls_proposed TO lt_proposed.
  ls_proposed-fname = 'P0001-ABKRS'. ls_proposed-fval = is_basic-abkrs. APPEND ls_proposed TO lt_proposed.

  " ---- IT0001 : Position-derived org fields (not auto-populated in BDC simulation) ----
  ls_proposed-fname = 'P0001-WERKS'. ls_proposed-fval = is_basic-werks. APPEND ls_proposed TO lt_proposed.
  ls_proposed-fname = 'P0001-BTRTL'. ls_proposed-fval = is_basic-btrtl. APPEND ls_proposed TO lt_proposed.
  ls_proposed-fname = 'P0001-PLANS'. ls_proposed-fval = is_basic-plans. APPEND ls_proposed TO lt_proposed.
* ls_proposed-fname = 'P0001-ORGEH'. ls_proposed-fval = '00000577'. APPEND ls_proposed TO lt_proposed.
* ls_proposed-fname = 'P0001-STELL'. ls_proposed-fval = '00000000'. APPEND ls_proposed TO lt_proposed.
* ls_proposed-fname = 'P0001-KOSTL'. ls_proposed-fval = '1300023'.  APPEND ls_proposed TO lt_proposed.

  " ---- IT0002 : Personal Data ----
  ls_proposed-infty = '0002'.
  ls_proposed-fname = 'P0002-ANRED'. ls_proposed-fval = is_basic-anred. APPEND ls_proposed TO lt_proposed.
  ls_proposed-fname = 'P0002-NACHN'. ls_proposed-fval = is_basic-nachn. APPEND ls_proposed TO lt_proposed.
  ls_proposed-fname = 'P0002-VORNA'. ls_proposed-fval = is_basic-vorna. APPEND ls_proposed TO lt_proposed.
  ls_proposed-fname = 'P0002-GESCH'. ls_proposed-fval = is_basic-gesch. APPEND ls_proposed TO lt_proposed.
  ls_proposed-fname = 'P0002-GBDAT'. ls_proposed-fval = is_basic-gbdat. APPEND ls_proposed TO lt_proposed.
  ls_proposed-fname = 'P0002-NATIO'. ls_proposed-fval = is_basic-natio. APPEND ls_proposed TO lt_proposed.
  ls_proposed-fname = 'P0002-FAMST'. ls_proposed-fval = is_basic-famst. APPEND ls_proposed TO lt_proposed.
  ls_proposed-fname = 'P0002-SPRSL'. ls_proposed-fval = 'EN'. APPEND ls_proposed TO lt_proposed.

  " ---- IT0006 : Address (required by this system's infogroup for action 01) ----
  ls_proposed-infty = '0006'.
  ls_proposed-fname = 'P0006-SUBTY'. ls_proposed-fval = is_basic-anssa. APPEND ls_proposed TO lt_proposed.
  ls_proposed-fname = 'P0006-STRAS'. ls_proposed-fval = is_basic-stras. APPEND ls_proposed TO lt_proposed.
  ls_proposed-fname = 'P0006-LOCAT'. ls_proposed-fval = is_basic-locat. APPEND ls_proposed TO lt_proposed.
  ls_proposed-fname = 'P0006-PSTLZ'. ls_proposed-fval = is_basic-pstlz. APPEND ls_proposed TO lt_proposed.
  ls_proposed-fname = 'P0006-ORT01'. ls_proposed-fval = is_basic-ort01. APPEND ls_proposed TO lt_proposed.
  ls_proposed-fname = 'P0006-LAND1'. ls_proposed-fval = is_basic-land1. APPEND ls_proposed TO lt_proposed.

  " ---- IT0007 : Planned Working Time (required by this system's infogroup) ----
  ls_proposed-infty = '0007'.
  ls_proposed-fname = 'P0007-SCHKZ'. ls_proposed-fval = is_basic-schkz. APPEND ls_proposed TO lt_proposed.

  " ---- IT0008 : Basic Pay (required by this system's infogroup) ----
  ls_proposed-infty = '0008'.
  ls_proposed-fname = 'P0008-LGA01'. ls_proposed-fval = '0001'.            APPEND ls_proposed TO lt_proposed.
  ls_proposed-fname = 'P0008-BET01'. ls_proposed-fval = is_basic-wt_0001. APPEND ls_proposed TO lt_proposed.
  ls_proposed-fname = 'P0008-WAERS'. ls_proposed-fval = 'PKR'.            APPEND ls_proposed TO lt_proposed.
  ls_proposed-fname = 'P0008-TRFGB'. ls_proposed-fval = '99'.             APPEND ls_proposed TO lt_proposed.
  ls_proposed-fname = 'P0008-TRFAR'. ls_proposed-fval = '99'.             APPEND ls_proposed TO lt_proposed.
  ls_proposed-fname = 'P0008-TRFGR'. ls_proposed-fval = 'JG'.             APPEND ls_proposed TO lt_proposed.
  ls_proposed-fname = 'P0008-TRFST'. ls_proposed-fval = '03'.             APPEND ls_proposed TO lt_proposed.
  ls_proposed-fname = 'P0008-BSGRD'. ls_proposed-fval = '100.00'.         APPEND ls_proposed TO lt_proposed.
  ls_proposed-fname = 'P0008-INDGR'. ls_proposed-fval = 'PER'.            APPEND ls_proposed TO lt_proposed.
  ls_proposed-fname = 'P0008-DIVGV'. ls_proposed-fval = '176.00'.         APPEND ls_proposed TO lt_proposed.
  ls_proposed-fname = 'P0008-ANSAL'. ls_proposed-fval = '0.00'.           APPEND ls_proposed TO lt_proposed.
  ls_proposed-fname = 'P0008-ZEINH'. ls_proposed-fval = 'M'.              APPEND ls_proposed TO lt_proposed.  " confirm unit code for Monthly


  " ---- Perform the hire action ----
  CALL FUNCTION 'HR_MAINTAIN_MASTERDATA'
    EXPORTING
      pernr              = '00000000'
      massn              = is_basic-massn
      actio              = 'INS'          " changed from 'INSS'
      tclas              = 'A'
      begda              = lv_begda
      endda              = '99991231'
      werks              = is_basic-werks
      persg              = is_basic-persg
      persk              = is_basic-persk
      plans              = is_basic-plans
      btrtl              = is_basic-btrtl
      dialog_mode        = '0'
      no_existence_check = 'X'
      no_enqueue         = ' '
    IMPORTING
      return             = ls_return
      return1            = ls_return1
      hr_return          = ls_hr_return
    TABLES
      proposed_values    = lt_proposed
      modified_keys      = lt_modkeys.

  " ---- Check for errors ----
  IF ls_return-type = 'E' OR ls_return1-type = 'E'.
    DATA(ls_err) = VALUE bapireturn1(
      type    = 'E'
      message = COND #( WHEN ls_return1-message IS NOT INITIAL
                         THEN ls_return1-message
                         ELSE ls_return-message ) ).
    APPEND ls_err TO et_return.
    RETURN.
  ENDIF.


  " ---- Pull the newly created PERNR from modified_keys ----
  READ TABLE lt_modkeys INTO ls_modkey INDEX 1.
  IF sy-subrc <> 0 OR ls_modkey-pernr IS INITIAL.
    DATA(ls_err2) = VALUE bapireturn1(
      type    = 'E'
      message = 'Hire call returned no error but no PERNR was created' ).
    APPEND ls_err2 TO et_return.
    RETURN.
  ENDIF.

  ev_pernr = ls_modkey-pernr.

  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
    EXPORTING
      wait = 'X'.


  ENDFUNCTION.
