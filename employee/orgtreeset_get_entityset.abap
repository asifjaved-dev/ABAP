METHOD orgtreeset_get_entityset.

  DATA lt_tree TYPE zaj_hr_org_tree_t.

  CALL FUNCTION 'ZAJ_HR_GET_ORG_TREE'
    EXPORTING
      iv_root_org = '00000001'
    IMPORTING
      et_org_tree = lt_tree.

  et_entityset = CORRESPONDING #( lt_tree ).

ENDMETHOD.
