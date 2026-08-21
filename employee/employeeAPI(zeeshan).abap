FUNCTION zhcm_emp_hiring_upd.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(IV_PAYLOAD) TYPE  STRING
*"     REFERENCE(IV_CTUMODE) TYPE  CTU_MODE DEFAULT 'N'
*"  EXPORTING
*"     REFERENCE(EV_PERNR) TYPE  PERNR_D
*"  TABLES
*"      ET_RETURN STRUCTURE  BDCMSGCOLL
*"----------------------------------------------------------------------
  TYPES: BEGIN OF ty_salarycomponents,
           lgart TYPE lgart,
           waers TYPE waers,
           betrg TYPE pad_amt7s,
         END OF ty_salarycomponents.
  TYPES: BEGIN OF ty_recurringpaymentsdeductions,
           lgart TYPE lgart,
           waers TYPE waers,
           betrg TYPE pad_amt7s,
         END OF ty_recurringpaymentsdeductions.
  TYPES: BEGIN OF ty_addresses,
           anssa TYPE pa0006-anssa,
           stras TYPE pa0006-stras,
           ort01 TYPE pa0006-ort01,
           pstlz TYPE pa0006-pstlz,
           land1 TYPE pa0006-land1,
         END OF ty_addresses.
  TYPES: BEGIN OF ty_identificationnumbers,
           ictyp TYPE pa0185-ictyp,
           icnum TYPE pa0185-icnum,
         END OF ty_identificationnumbers.
  TYPES: BEGIN OF ty_familymembers,
           famsa  TYPE pa0021-famsa,
           favor  TYPE pa0021-favor,
           fanam  TYPE pa0021-fanam,
           gender TYPE char01,
         END OF ty_familymembers.
  TYPES: BEGIN OF ty_communication,
           usrty TYPE pa0105-usrty,
           usrid TYPE pa0105-usrid,
         END OF ty_communication.
  TYPES: BEGIN OF ty_payload,
           begda                       TYPE char10,
           massn                       TYPE pa0000-massn,
           massg                       TYPE pa0000-massg,
           bukrs                       TYPE pa0001-bukrs,
           werks                       TYPE pa0001-werks,
           btrtl                       TYPE pa0001-btrtl,
           persg                       TYPE pa0001-persg,
           persk                       TYPE pa0001-persk,
           orgeh                       TYPE pa0001-orgeh,
           plans                       TYPE pa0001-plans,
           vorna                       TYPE pa0002-vorna,
           nachn                       TYPE pa0002-nachn,
           gbdat                       TYPE char10,
           gesch                       TYPE pa0002-gesch,
           famst                       TYPE pa0002-famst,
           addresses                   TYPE TABLE OF ty_addresses WITH NON-UNIQUE DEFAULT KEY,
           schkz                       TYPE pa0007-schkz,
           wostd                       TYPE pa0007-wostd,
           ctbeg                       TYPE char10,
           banks                       TYPE pa0009-banks,
           bankl                       TYPE pa0009-bankl,
           bankn                       TYPE pa0009-bankn,
           trfgr                       TYPE pa0008-trfgr,
           trfst                       TYPE pa0008-trfst,
           salarycomponents            TYPE TABLE OF ty_salarycomponents WITH NON-UNIQUE DEFAULT KEY,
           recurringpaymentsdeductions TYPE TABLE OF ty_recurringpaymentsdeductions WITH NON-UNIQUE DEFAULT KEY,
           identificationnumbers       TYPE TABLE OF ty_identificationnumbers WITH NON-UNIQUE DEFAULT KEY,
           familymembers               TYPE TABLE OF ty_familymembers WITH NON-UNIQUE DEFAULT KEY,
           communication               TYPE TABLE OF ty_communication WITH NON-UNIQUE DEFAULT KEY,
         END OF ty_payload.

  DATA: it_mesg       TYPE STANDARD TABLE OF bdcmsgcoll,
        ls_ctu        TYPE ctu_params,
        lv_ctumode    TYPE ctu_mode,
        lv_einda_ext  TYPE char10,
        emp_creat_key TYPE string,
        iv_einda      TYPE sy-datum,
        ev_subrc      TYPE sy-subrc,
        ls_payload    TYPE ty_payload,
        lv_lgart_t    TYPE char70,
        lv_betrg_t    TYPE char70,
        lv_counter    TYPE int2,
        lv_text       TYPE char100
        .

  /ui2/cl_json=>deserialize(
    EXPORTING
      json = iv_payload
    CHANGING
      data = ls_payload
    ).

  CONCATENATE sy-datum 'EMP_KEY_API' INTO emp_creat_key.
  EXPORT emp_creat_key FROM emp_creat_key TO MEMORY ID 'EMP_CREAT_KEY'.

  ls_ctu-dismode = iv_ctumode.
  ls_ctu-updmode = 'S'.   " S = Synchronous
  ls_ctu-nobinpt = 'X'.   " no batch input
*  ls_ctu-racommit = 'X'.

  PERFORM bdc_dynpro      USING 'SAPMP50A' '2000'.
  PERFORM bdc_field       USING 'BDC_CURSOR'
                                'RP50G-PERNR'.
  PERFORM bdc_field       USING 'BDC_OKCODE'
                                '/00'.
  PERFORM bdc_field       USING 'RP50G-PERNR'
                                ''.

  PERFORM bdc_dynpro      USING 'SAPMP50A' '2000'.
  PERFORM bdc_field       USING 'BDC_CURSOR'
                                'RP50G-EINDA'.
  PERFORM bdc_field       USING 'BDC_OKCODE'
                                '/00'.
  PERFORM bdc_field       USING 'RP50G-EINDA'
                                ls_payload-begda."'11.08.2026'.
  PERFORM bdc_field       USING 'RP50G-SELEC(01)'
                                'X'.

  PERFORM bdc_dynpro      USING 'SAPMP50A' '2000'.
  PERFORM bdc_field       USING 'BDC_CURSOR'
                                'RP50G-PERNR'.
  PERFORM bdc_field       USING 'BDC_OKCODE'
                                '=PICK'.
  PERFORM bdc_field       USING 'RP50G-EINDA'
                                ls_payload-begda."'11.08.2026'.

  PERFORM bdc_dynpro      USING 'MP000000' '2000'.
  PERFORM bdc_field       USING 'BDC_CURSOR'
                                'PSPAR-PLANS'.
  PERFORM bdc_field       USING 'BDC_OKCODE'
                                '=UPD'."'/00'.
*  PERFORM bdc_field       USING 'PSPAR-PERNR'
*                                ''.
  PERFORM bdc_field       USING 'P0000-BEGDA'
                                ls_payload-begda."'11.08.2026'.
  PERFORM bdc_field       USING 'P0000-ENDDA'
                                '31.12.9999'.
  PERFORM bdc_field       USING 'P0000-MASSN'
                                ls_payload-massn."'Z1'.
  PERFORM bdc_field       USING 'P0000-MASSG'
                                ls_payload-massg."'01'.
*  PERFORM bdc_field       USING 'Q0000-RFPNR'
*                                ''.
  PERFORM bdc_field       USING 'PSPAR-PLANS'
                                ls_payload-plans."'50000001'.
  PERFORM bdc_field       USING 'PSPAR-WERKS'
                                ls_payload-werks."'1100'.
  PERFORM bdc_field       USING 'PSPAR-PERSG'
                                ls_payload-persg."'5'.
  PERFORM bdc_field       USING 'PSPAR-PERSK'
                                ls_payload-persk."'18'.

*  PERFORM bdc_dynpro      USING 'MP000000' '2000'.
*  PERFORM bdc_field       USING 'BDC_CURSOR'
*                                'PSPAR-PERNR'.
*  PERFORM bdc_field       USING 'BDC_OKCODE'
*                                '=UPD'.
**  PERFORM bdc_field       USING 'PSPAR-PERNR'
**                                ' 8000017'.
*  PERFORM bdc_field       USING 'P0000-BEGDA'
*                                ls_payload-begda."'11.08.2026'.
*  PERFORM bdc_field       USING 'P0000-ENDDA'
*                                '31.12.9999'.
*  PERFORM bdc_field       USING 'P0000-MASSN'
*                                ls_payload-massn."'Z1'.
*  PERFORM bdc_field       USING 'P0000-MASSG'
*                                ls_payload-massg."'01'.
*  PERFORM bdc_field       USING 'PSPAR-PLANS'
*                                ls_payload-plans."'50000001'.
*  PERFORM bdc_field       USING 'PSPAR-WERKS'
*                                ls_payload-werks."'1100'.
*  PERFORM bdc_field       USING 'PSPAR-PERSG'
*                                ls_payload-persg."'5'.
*  PERFORM bdc_field       USING 'PSPAR-PERSK'
*                                ls_payload-persk."'18'.

  PERFORM bdc_dynpro      USING 'MP000100' '2000'.
  PERFORM bdc_field       USING 'BDC_CURSOR'
                                'P0001-BTRTL'.
  PERFORM bdc_field       USING 'BDC_OKCODE'
                                '=UPD'."'/00'.
  PERFORM bdc_field       USING 'P0000-BEGDA'
                                ls_payload-begda."'11.08.2026'.
  PERFORM bdc_field       USING 'P0000-ENDDA'
                                '31.12.9999'.
  PERFORM bdc_field       USING 'P0001-BTRTL'
                                ls_payload-btrtl."'1102'.
*  PERFORM bdc_field       USING 'P0001-KOSTL'
*                                '1110001'.
*  PERFORM bdc_field       USING 'P0001-GSBER'
*                                '2002'.
*  PERFORM bdc_field       USING 'P0001-ABKRS'
*                                'Z1'.
*  PERFORM bdc_field       USING 'P0001-PLANS'
*                                '50000001'.
*  PERFORM bdc_field       USING 'P0001-ORGEH'
*                                '00000102'.

*  PERFORM bdc_dynpro      USING 'MP000100' '2000'.
*  PERFORM bdc_field       USING 'BDC_CURSOR'
*                                'P0001-BEGDA'.
*  PERFORM bdc_field       USING 'BDC_OKCODE'
*                                '=UPD'.
*  PERFORM bdc_field       USING 'P0000-BEGDA'
*                                ls_payload-begda."'11.08.2026'.
*  PERFORM bdc_field       USING 'P0000-ENDDA'
*                                '31.12.9999'.
*  PERFORM bdc_field       USING 'P0001-BTRTL'
*                                ls_payload-btrtl."'1102'.
**  PERFORM bdc_field       USING 'P0001-KOSTL'
**                                '1110001'.
**  PERFORM bdc_field       USING 'P0001-GSBER'
**                                '2002'.
**  PERFORM bdc_field       USING 'P0001-ABKRS'
**                                'Z1'.
**  PERFORM bdc_field       USING 'P0001-PLANS'
**                                '50000001'.
**  PERFORM bdc_field       USING 'P0001-ORGEH'
**                                '00000102'.
**  PERFORM bdc_field       USING 'P0001-VDSK1'
**                                '11000001110001'.

  PERFORM bdc_dynpro      USING 'MP000200' '2000'.
  PERFORM bdc_field       USING 'BDC_CURSOR'
                                'Q0002-FATXT'.
  PERFORM bdc_field       USING 'BDC_OKCODE'
                                '=UPD'."'/00'.
  PERFORM bdc_field       USING 'P0002-BEGDA'
                                ls_payload-begda."'11.08.2026'.
  PERFORM bdc_field       USING 'P0002-ENDDA'
                                '31.12.9999'.
  PERFORM bdc_field       USING 'P0002-NACHN'
                                ls_payload-vorna."'firstName2'.
  PERFORM bdc_field       USING 'P0002-VORNA'
                                ls_payload-nachn."'LastName2'.
  PERFORM bdc_field       USING 'P0002-SPRSL'
                                'EN'.
  PERFORM bdc_field       USING 'P0002-GBDAT'
                                ls_payload-gbdat."'01.01.2000'.
  DATA(lv_gender) = SWITCH #( ls_payload-gesch WHEN '1' THEN 'Male'
                                               WHEN '2' THEN 'Female' ).
  PERFORM bdc_field       USING 'P0002-GESCH'
                                lv_gender.
  DATA(lv_famst) = SWITCH #( ls_payload-gesch WHEN '0' THEN 'Single'
                                               WHEN '1' THEN 'Marr.'
                                               WHEN '2' THEN 'Wid.'
                                               WHEN '3' THEN 'Div.'
                                               WHEN '4' THEN 'NM'
                                               WHEN '5' THEN 'Sep.'
                                               WHEN '6' THEN 'Unknwn'
                                               WHEN '9' THEN 'RegCou'
                                               WHEN 'A' THEN 'RescRP' ).
  PERFORM bdc_field       USING 'Q0002-FATXT'
                                lv_famst.
  PERFORM bdc_field       USING 'P0002-NATIO'
                                'PK'.

*  PERFORM bdc_dynpro      USING 'MP000200' '2000'.
*  PERFORM bdc_field       USING 'BDC_CURSOR'
*                                'P0002-BEGDA'.
*  PERFORM bdc_field       USING 'BDC_OKCODE'
*                                '=UPD'.
*  PERFORM bdc_field       USING 'P0002-BEGDA'
*                                ls_payload-begda."'11.08.2026'.
*  PERFORM bdc_field       USING 'P0002-ENDDA'
*                                '31.12.9999'.
*  PERFORM bdc_field       USING 'P0002-NACHN'
*                                ls_payload-vorna."'firstName2'.
*  PERFORM bdc_field       USING 'P0002-VORNA'
*                                ls_payload-nachn."'LastName2'.
*  PERFORM bdc_field       USING 'P0002-SPRSL'
*                                'EN'.
*  PERFORM bdc_field       USING 'P0002-GBDAT'
*                                ls_payload-gbdat."'01.01.2000'.
*  PERFORM bdc_field       USING 'P0002-GESCH'
*                                lv_gender.
*  PERFORM bdc_field       USING 'Q0002-FATXT'
*                                lv_famst.
*  PERFORM bdc_field       USING 'P0002-NATIO'
*                                'PK'.

  LOOP AT ls_payload-addresses ASSIGNING FIELD-SYMBOL(<fs_addr>).
    PERFORM bdc_dynpro      USING 'MP000600' '2000'.
    PERFORM bdc_field       USING 'BDC_CURSOR'
                                  'P0006-PSTLZ'.
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '=UPD'."'/00'.
    PERFORM bdc_field       USING 'P0006-BEGDA'
                                  ls_payload-begda."'11.08.2026'.
    PERFORM bdc_field       USING 'P0006-ENDDA'
                                  '31.12.9999'.
    DATA(lv_anssa) = SWITCH #( <fs_addr>-anssa WHEN '1' THEN 'Permanent residence'
                                                 WHEN '2' THEN 'Temporary residence'
                                                 WHEN '3' THEN 'Home address'
                                                 WHEN '4' THEN 'Emergency address'
                                                 WHEN '5' THEN 'Mailing address'
                                                 WHEN '6' THEN 'Nursing address'
                                                 WHEN '7' THEN '' ).
    PERFORM bdc_field       USING 'P0006-ANSSA'
                                  lv_anssa.
    PERFORM bdc_field       USING 'P0006-PSTLZ'
                                  <fs_addr>-pstlz.
    PERFORM bdc_field       USING 'P0006-ORT01'
                                  <fs_addr>-ort01.
    PERFORM bdc_field       USING 'P0006-LAND1'
                                  <fs_addr>-land1.

*    PERFORM bdc_dynpro      USING 'MP000600' '2000'.
*    PERFORM bdc_field       USING 'BDC_CURSOR'
*                                  'P0006-BEGDA'.
*    PERFORM bdc_field       USING 'BDC_OKCODE'
*                                  '=UPD'.
*    PERFORM bdc_field       USING 'P0006-BEGDA'
*                                  ls_payload-begda."'11.08.2026'.
*    PERFORM bdc_field       USING 'P0006-ENDDA'
*                                  '31.12.9999'.
*    PERFORM bdc_field       USING 'P0006-ANSSA'
*                                  lv_anssa.
*    PERFORM bdc_field       USING 'P0006-PSTLZ'
*                                  <fs_addr>-pstlz.
*    PERFORM bdc_field       USING 'P0006-ORT01'
*                                  <fs_addr>-ort01.
*    PERFORM bdc_field       USING 'P0006-LAND1'
*                                  <fs_addr>-land1.
  ENDLOOP.

  PERFORM bdc_dynpro      USING 'MP000700' '2000'.
  PERFORM bdc_field       USING 'BDC_CURSOR'
                                'P0007-SCHKZ'.
  PERFORM bdc_field       USING 'BDC_OKCODE'
                                '=UPD'."'/00'.
  PERFORM bdc_field       USING 'P0007-BEGDA'
                                ls_payload-begda."'11.08.2026'.
  PERFORM bdc_field       USING 'P0007-ENDDA'
                                '31.12.9999'.
  PERFORM bdc_field       USING 'P0007-SCHKZ'
                                ls_payload-schkz."'IMR1'.
  PERFORM bdc_field       USING 'P0007-EMPCT'
                                '  100.00'.

*  PERFORM bdc_dynpro      USING 'MP000700' '2000'.
*  PERFORM bdc_field       USING 'BDC_CURSOR'
*                                'P0007-BEGDA'.
*  PERFORM bdc_field       USING 'BDC_OKCODE'
*                                '=UPD'.
*  PERFORM bdc_field       USING 'P0007-BEGDA'
*                                ls_payload-begda."'11.08.2026'.
*  PERFORM bdc_field       USING 'P0007-ENDDA'
*                                '31.12.9999'.
*  PERFORM bdc_field       USING 'P0007-SCHKZ'
*                                ls_payload-schkz."'IMR1'.
*  PERFORM bdc_field       USING 'P0007-EMPCT'
*                                '  100.00'.

  PERFORM bdc_dynpro      USING 'MP000800' '2000'.
  PERFORM bdc_field       USING 'BDC_CURSOR'
                                'P0008-BEGDA'.
  PERFORM bdc_field       USING 'BDC_OKCODE'
                                '=UPD'.
  PERFORM bdc_field       USING 'P0008-BEGDA'
                                ls_payload-begda."'11.08.2026'.
  PERFORM bdc_field       USING 'P0008-ENDDA'
                                '31.12.9999'.
*  PERFORM bdc_field       USING 'P0008-TRFAR'
*                                '99'.
*  PERFORM bdc_field       USING 'P0008-BSGRD'
*                                '100.00'.
  PERFORM bdc_field       USING 'P0008-TRFGB'
                                '99'.
  PERFORM bdc_field       USING 'P0008-TRFGR'
                                ls_payload-trfgr."'JG'.
  PERFORM bdc_field       USING 'P0008-TRFST'
                                ls_payload-trfst."'02'.
*  PERFORM bdc_field       USING 'P0008-DIVGV'
*                                '176.00'.
*  PERFORM bdc_field       USING 'P0008-ANCUR'
*                                'PKR'.
*  PERFORM bdc_field       USING 'Q0008-IBBEG'
*                                '05.07.2026'.
*  PERFORM bdc_field       USING 'P0008-WAERS'
*                                'PKR'.
  lv_counter = 0.
  LOOP AT ls_payload-salarycomponents ASSIGNING FIELD-SYMBOL(<fs_sal>).
    lv_counter = lv_counter + 1.
    lv_lgart_t = |Q0008-LGART({ lv_counter })|.
    lv_betrg_t = |Q0008-BETRG({ lv_counter })|.
    PERFORM bdc_field       USING lv_lgart_t
                                  <fs_sal>-lgart.
    PERFORM bdc_field       USING lv_betrg_t "'Q0008-BETRG(01)'
                                  <fs_sal>-betrg."'             40000'.
  ENDLOOP.
*
*  PERFORM bdc_dynpro      USING 'MP000800' '2000'.
*  PERFORM bdc_field       USING 'BDC_OKCODE'
*                                '/00'.
*  PERFORM bdc_field       USING 'P0008-BEGDA'
*                                ls_payload-begda."'11.08.2026'.
*  PERFORM bdc_field       USING 'P0008-ENDDA'
*                                '31.12.9999'.
*  PERFORM bdc_field       USING 'P0008-TRFAR'
*                                '99'.
*  PERFORM bdc_field       USING 'P0008-BSGRD'
*                                '100.00'.
*  PERFORM bdc_field       USING 'P0008-TRFGB'
*                                '99'.
*  PERFORM bdc_field       USING 'P0008-TRFGR'
*                                'JG'.
*  PERFORM bdc_field       USING 'P0008-TRFST'
*                                '02'.
*  PERFORM bdc_field       USING 'P0008-DIVGV'
*                                '176.00'.
*  PERFORM bdc_field       USING 'P0008-ANCUR'
*                                'PKR'.
*  PERFORM bdc_field       USING 'BDC_CURSOR'
*                                'Q0008-BETRG(01)'.
*  PERFORM bdc_field       USING 'Q0008-IBBEG'
*                                '05.07.2026'.
*  PERFORM bdc_field       USING 'P0008-WAERS'
*                                'PKR'.
*  PERFORM bdc_field       USING 'Q0008-BETRG(01)'
*                                '             40000'.

  PERFORM bdc_dynpro      USING 'MP000900' '2000'.
  PERFORM bdc_field       USING 'BDC_CURSOR'
                                'P0009-ZLSCH'.
  PERFORM bdc_field       USING 'BDC_OKCODE'
                                '=UPD'.
  PERFORM bdc_field       USING 'P0009-BEGDA'
                                ls_payload-begda."'11.08.2026'.
  PERFORM bdc_field       USING 'P0009-ENDDA'
                                '31.12.9999'.
*  PERFORM bdc_field       USING 'P0009-BNKSA'
*                                '0'.
*  PERFORM bdc_field       USING 'Q0009-EMFTX'
*                                'LastName2 firstName2'.
*  PERFORM bdc_field       USING 'Q0009-BKPLZ'
*                                '44000'.
*  PERFORM bdc_field       USING 'Q0009-BKORT'
*                                'Islamabad'.
*  PERFORM bdc_field       USING 'Q0009-ADRS_BANKS'
*                                'PK'.
  PERFORM bdc_field       USING 'P0009-BANKS'
                                ls_payload-banks."'PK'.
  PERFORM bdc_field       USING 'P0009-BANKL'
                                ls_payload-bankl."'ABL'.
  PERFORM bdc_field       USING 'P0009-BANKN'
                                ls_payload-bankn."'01112342342345'.
  PERFORM bdc_field       USING 'P0009-ZLSCH'
                                'B'.
*  PERFORM bdc_field       USING 'P0009-WAERS'
*                                'PKR'.
*  PERFORM bdc_field       USING 'P0009-BKONT'
*                                ''.

*  PERFORM bdc_dynpro      USING 'MP000900' '2000'.
*  PERFORM bdc_field       USING 'BDC_CURSOR'
*                                'P0009-ZLSCH'.
*  PERFORM bdc_field       USING 'BDC_OKCODE'
*                                '=UPD'.
*  PERFORM bdc_field       USING 'P0009-BEGDA'
*                                ls_payload-begda."'11.08.2026'.
*  PERFORM bdc_field       USING 'P0009-ENDDA'
*                                '31.12.9999'.
**  PERFORM bdc_field       USING 'P0009-BNKSA'
**                                '0'.
**  PERFORM bdc_field       USING 'Q0009-EMFTX'
**                                'LastName2 firstName2'.
**  PERFORM bdc_field       USING 'Q0009-BKPLZ'
**                                '44000'.
**  PERFORM bdc_field       USING 'Q0009-BKORT'
**                                'Islamabad'.
**  PERFORM bdc_field       USING 'Q0009-ADRS_BANKS'
**                                'PK'.
*  PERFORM bdc_field       USING 'P0009-BANKS'
*                                ls_payload-BANKS."'PK'.
*  PERFORM bdc_field       USING 'P0009-BANKL'
*                                ls_payload-BANKL."'ABL'.
*  PERFORM bdc_field       USING 'P0009-BANKN'
*                                ls_payload-BANKN."'01112342342345'.
*  PERFORM bdc_field       USING 'P0009-ZLSCH'
*                                'B'.
**  PERFORM bdc_field       USING 'P0009-WAERS'
**                                'PKR'.
**  PERFORM bdc_field       USING 'P0009-BKONT'
**                                ''.

  PERFORM bdc_dynpro      USING 'MP001600' '2000'.
  PERFORM bdc_field       USING 'BDC_CURSOR'
                                'P0016-BEGDA'.
  PERFORM bdc_field       USING 'BDC_OKCODE'
                                '=UPD'.
  PERFORM bdc_field       USING 'P0016-BEGDA'
                                ls_payload-begda."'11.08.2026'.
  PERFORM bdc_field       USING 'P0016-ENDDA'
                                '31.12.9999'.
*  PERFORM bdc_field       USING 'P0016-CTTYP'
*                                '01'.
*  PERFORM bdc_field       USING 'P0016-LFZFR'
*                                ' 42'.
*  PERFORM bdc_field       USING 'Q0016-LFZZH'
*                                'Days'.
*  PERFORM bdc_field       USING 'P0016-KGZFR'
*                                '  6'.
*  PERFORM bdc_field       USING 'Q0016-KGZZH'
*                                'Months'.
*  PERFORM bdc_field       USING 'P0016-PRBZT'
*                                '  3'.
*  PERFORM bdc_field       USING 'Q0016-PRBEH'
*                                'Months'.
*  PERFORM bdc_field       USING 'P0016-KDGFR'
*                                '13'.
*  PERFORM bdc_field       USING 'P0016-KDGF2'
*                                '13'.

  LOOP AT ls_payload-recurringpaymentsdeductions ASSIGNING FIELD-SYMBOL(<fs_pay>).
    PERFORM bdc_dynpro      USING 'MP001400' '2010'.
    PERFORM bdc_field       USING 'BDC_CURSOR'
                                  'Q0014-BETRG'.
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '=UPD'.
    PERFORM bdc_field       USING 'P0014-BEGDA'
                                  ls_payload-begda."'11.08.2026'.
    PERFORM bdc_field       USING 'P0014-ENDDA'
                                  '31.12.9999'.
    PERFORM bdc_field       USING 'P0014-LGART'
                                  <fs_pay>-lgart."'3001'.
    PERFORM bdc_field       USING 'Q0014-BETRG'
                                  <fs_pay>-betrg."'               350'.
    PERFORM bdc_field       USING 'P0014-WAERS'
                                  <fs_pay>-waers. "'PKR'.
  ENDLOOP.

*  PERFORM bdc_dynpro      USING 'SAPMSSY0' '0120'.
*  PERFORM bdc_field       USING 'BDC_CURSOR'
*                                '04/08'.
*  PERFORM bdc_field       USING 'BDC_OKCODE'
*                                '=PICK'.

  LOOP AT ls_payload-identificationnumbers ASSIGNING FIELD-SYMBOL(<fs_id>).
    PERFORM bdc_dynpro      USING 'MP018500' '2000'.
    PERFORM bdc_field       USING 'BDC_CURSOR'
                                  'P0185-ICNUM'.
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '=UPD'.
    PERFORM bdc_field       USING 'P0185-BEGDA'
                                  ls_payload-begda."'11.08.2026'.
    PERFORM bdc_field       USING 'P0185-ENDDA'
                                  '31.12.9999'.
    PERFORM bdc_field       USING 'P0185-ICTYP'
                                  <fs_id>-ictyp.
    PERFORM bdc_field       USING 'P0185-ICNUM'
                                  <fs_id>-icnum."'3310512345679'.
  ENDLOOP.

*  PERFORM bdc_dynpro      USING 'MP018500' '2000'.
*  PERFORM bdc_field       USING 'BDC_CURSOR'
*                                'P0185-BEGDA'.
*  PERFORM bdc_field       USING 'BDC_OKCODE'
*                                '=UPD'.
*  PERFORM bdc_field       USING 'P0185-BEGDA'
*                                ls_payload-begda."'11.08.2026'.
*  PERFORM bdc_field       USING 'P0185-ENDDA'
*                                '31.12.9999'.
*  PERFORM bdc_field       USING 'P0185-ICNUM'
*                                '3310512345679'.

  PERFORM bdc_dynpro      USING 'MP004100' '2000'.
  PERFORM bdc_field       USING 'BDC_CURSOR'
                                'P0041-DAT01'.
  PERFORM bdc_field       USING 'BDC_OKCODE'
                                '=UPD'.
  PERFORM bdc_field       USING 'P0041-BEGDA'
                                ls_payload-begda."'11.08.2026'.
  PERFORM bdc_field       USING 'P0041-ENDDA'
                                '31.12.9999'.
  PERFORM bdc_field       USING 'P0041-DAR01'
                                'Z1'.
  PERFORM bdc_field       USING 'P0041-DAT01'
                                ls_payload-begda.

*  PERFORM bdc_dynpro      USING 'SAPMSSY0' '0120'.
*  PERFORM bdc_field       USING 'BDC_CURSOR'
*                                '04/09'.
*  PERFORM bdc_field       USING 'BDC_OKCODE'
*                                '=PICK'.

  LOOP AT ls_payload-familyMembers ASSIGNING FIELD-SYMBOL(<fs_family>).
    PERFORM bdc_dynpro      USING 'MP002100' '2000'.
    PERFORM bdc_field       USING 'BDC_CURSOR'
                                  'P0021-FAVOR'.
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '=UPD'.
    PERFORM bdc_field       USING 'P0021-BEGDA'
                                  ls_payload-begda."'11.08.2026'.
    PERFORM bdc_field       USING 'P0021-ENDDA'
                                  '31.12.9999'.
    PERFORM bdc_field       USING 'P0021-FAMSA'
                                  <fs_family>-famsa.
    PERFORM bdc_field       USING 'P0021-FANAM'
                                  <fs_family>-fanam.
    PERFORM bdc_field       USING 'P0021-FAVOR'
                                  <fs_family>-favor.
    lv_text = SWITCH #( <fs_family>-gender WHEN '1' THEN 'Q0021-GESC1'
                                           WHEN '2' THEN 'Q0021-GESC2' ).
    PERFORM bdc_field       USING lv_text
                                  'X'.
*    PERFORM bdc_field       USING 'P0021-FANAT'
*                                  'PK'.
  ENDLOOP.

  LOOP AT ls_payload-communication ASSIGNING FIELD-SYMBOL(<fs_com>).
    PERFORM bdc_dynpro      USING 'MP010500' '2000'.
    PERFORM bdc_field       USING 'BDC_CURSOR'
                                  'P0105-USRID'.
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '=UPD'.
    PERFORM bdc_field       USING 'P0105-BEGDA'
                                  ls_payload-begda."'11.08.2026'.
    PERFORM bdc_field       USING 'P0105-ENDDA'
                                  '31.12.9999'.
    PERFORM bdc_field       USING 'P0105-USRTY'
                                  <fs_com>-usrty.
    PERFORM bdc_field       USING 'P0105-USRID'
                                  <fs_com>-usrid."'03001234568'.
  ENDLOOP.

  PERFORM bdc_dynpro      USING 'SAPMP50A' '2000'.
  PERFORM bdc_field       USING 'BDC_OKCODE'
                                '/EBCK'.
  PERFORM bdc_field       USING 'BDC_CURSOR'
                                'RP50G-PERNR'.
*perform bdc_transaction using 'PA40' .

  CALL TRANSACTION 'PA40' WITHOUT AUTHORITY-CHECK
      USING   bdcdata
      OPTIONS FROM ls_ctu
      MESSAGES INTO it_mesg.

  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
    EXPORTING
      wait = abap_true
*   IMPORTING
*     RETURN        =
    .


  ev_subrc = sy-subrc.
  et_return[] = it_mesg[].

  IMPORT pernr TO ev_pernr FROM MEMORY ID 'EMP_CREAT_NUM'.
  FREE MEMORY ID 'EMP_CREAT_NUM'.
  FREE MEMORY ID 'EMP_CREAT_KEY'.


*  CONCATENATE ev_pernr 'New Employee Created' INTO DATA(msg) SEPARATED BY space.
*  MESSAGE msg TYPE 'I'.


ENDFUNCTION.

*&---------------------------------------------------------------------*
*&      Form  BDC_DYNPRO
*&---------------------------------------------------------------------*
FORM bdc_dynpro USING program dynpro.

  CLEAR bdcdata.
  bdcdata-program  = program.
  bdcdata-dynpro   = dynpro.
  bdcdata-dynbegin = 'X'.
  APPEND bdcdata.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  BDC_FIELD
*&---------------------------------------------------------------------*
FORM bdc_field USING fnam fval.

  CLEAR bdcdata.
  bdcdata-fnam = fnam.
  bdcdata-fval = fval.
  APPEND bdcdata.

ENDFORM.
