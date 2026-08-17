METHOD employeebasicset_create_entity.

  DATA: ls_basic  TYPE zaj_hr_employee_basic,
        lv_pernr  TYPE persno,
        lv_test   TYPE persno,
        lt_return TYPE STANDARD TABLE OF bapireturn1.

  io_data_provider->read_entry_data(
    IMPORTING es_data = ls_basic ).


  CALL FUNCTION 'ZAJ_HR_EMPLOYEE_CREATE_BASIC'
    EXPORTING
      is_basic  = ls_basic
    IMPORTING
      ev_pernr  = lv_pernr
    TABLES
      et_return = lt_return.

  READ TABLE lt_return TRANSPORTING NO FIELDS WITH KEY type = 'E'.
  IF sy-subrc = 0.
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
      EXPORTING
        message = 'Employee basic create failed'.
  ENDIF.

    ls_basic-pernr = lv_pernr.
    er_entity = ls_basic.


* copy_data_to_ref(
*   EXPORTING is_data = ls_basic
*   CHANGING  cr_data = lr_data ).

ENDMETHOD.
