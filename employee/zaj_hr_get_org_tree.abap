FUNCTION zaj_hr_get_org_tree.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(IV_ROOT_ORG) TYPE  HROBJID OPTIONAL
*"     REFERENCE(IV_BEGDA)    TYPE  SY-DATUM OPTIONAL
*"     REFERENCE(IV_ENDDA)    TYPE  SY-DATUM OPTIONAL
*"  EXPORTING
*"     REFERENCE(ET_ORG_TREE) TYPE  ZAJ_HR_ORG_TREE_T
*"  EXCEPTIONS
*"      INVALID_DATE_RANGE
*"      ROOT_ORG_NOT_FOUND
*"      INCONSISTENT_HIERARCHY
*"      INCONSISTENT_ACCOUNT_ASSIGNMENT
*"----------------------------------------------------------------------

*-----------------------------------------------------------------------
* Constants
*-----------------------------------------------------------------------
  CONSTANTS:
    gc_plvar             TYPE hrp1000-plvar VALUE '01',
    gc_otype_org         TYPE hrp1000-otype VALUE 'O',
    gc_istat_active      TYPE hrp1000-istat VALUE '1',
    gc_relation_org      TYPE hrp1001-relat VALUE '002',
    gc_rsign_down        TYPE hrp1001-rsign VALUE 'B',
    gc_fallback_language TYPE sylangu       VALUE 'E',
    gc_default_root      TYPE hrobjid       VALUE '00000001'.

*-----------------------------------------------------------------------
* Local types
*-----------------------------------------------------------------------
  TYPES:
    BEGIN OF ty_org_id,
      objid TYPE hrobjid,
    END OF ty_org_id,

    BEGIN OF ty_frontier,
      org_unit_id TYPE hrobjid,
      level       TYPE i,
    END OF ty_frontier,

    BEGIN OF ty_relationship,
      objid TYPE hrp1001-objid,
      sobid TYPE hrp1001-sobid,
    END OF ty_relationship,

    BEGIN OF ty_parent,
      objid        TYPE hrobjid,
      parent_objid TYPE hrobjid,
    END OF ty_parent,

    BEGIN OF ty_org_text,
      objid TYPE hrp1000-objid,
      stext TYPE hrp1000-stext,
      begda TYPE hrp1000-begda,
      endda TYPE hrp1000-endda,
      seqnr TYPE hrp1000-seqnr,
    END OF ty_org_text,

    BEGIN OF ty_account_assignment,
      objid TYPE hrp1008-objid,
      bukrs TYPE hrp1008-bukrs,
      persa TYPE hrp1008-persa,
      begda TYPE hrp1008-begda,
      endda TYPE hrp1008-endda,
      seqnr TYPE hrp1008-seqnr,
    END OF ty_account_assignment,

    BEGIN OF ty_effective_assignment,
      objid TYPE hrobjid,
      bukrs TYPE hrp1008-bukrs,
      persa TYPE hrp1008-persa,
    END OF ty_effective_assignment.

  TYPES:
    ty_org_id_t TYPE STANDARD TABLE OF ty_org_id
                WITH DEFAULT KEY,

    ty_visited_t TYPE HASHED TABLE OF ty_org_id
                 WITH UNIQUE KEY objid,

    ty_frontier_t TYPE HASHED TABLE OF ty_frontier
                  WITH UNIQUE KEY org_unit_id,

    ty_relationship_t TYPE STANDARD TABLE OF ty_relationship
                      WITH DEFAULT KEY,

    ty_parent_t TYPE HASHED TABLE OF ty_parent
                WITH UNIQUE KEY objid,

    ty_org_text_raw_t TYPE STANDARD TABLE OF ty_org_text
                      WITH DEFAULT KEY,

    ty_org_text_hash_t TYPE HASHED TABLE OF ty_org_text
                       WITH UNIQUE KEY objid,

    ty_account_raw_t TYPE STANDARD TABLE OF ty_account_assignment
                     WITH DEFAULT KEY,

    ty_account_hash_t TYPE HASHED TABLE OF ty_account_assignment
                      WITH UNIQUE KEY objid,

    ty_effective_t TYPE HASHED TABLE OF ty_effective_assignment
                   WITH UNIQUE KEY objid.

*-----------------------------------------------------------------------
* Local data
*-----------------------------------------------------------------------
  DATA:
    lv_root_org        TYPE hrobjid,
    lv_keydate         TYPE sy-datum,
    lv_root_exists     TYPE hrp1000-objid,
    lv_previous_objid  TYPE hrobjid,
    lv_have_previous   TYPE abap_bool,

    lt_nodes           TYPE STANDARD TABLE OF zaj_hr_org_tree_s
                       WITH DEFAULT KEY,

    lt_all_org_ids     TYPE ty_org_id_t,
    lt_missing_ids     TYPE ty_org_id_t,
    lt_visited         TYPE ty_visited_t,

    lt_frontier        TYPE ty_frontier_t,
    lt_next_frontier   TYPE ty_frontier_t,

    lt_relationships   TYPE ty_relationship_t,
    lt_parent_map      TYPE ty_parent_t,

    lt_text_raw        TYPE ty_org_text_raw_t,
    lt_text_by_id      TYPE ty_org_text_hash_t,

    lt_account_raw     TYPE ty_account_raw_t,
    lt_account_by_id   TYPE ty_account_hash_t,

    lt_effective_by_id TYPE ty_effective_t.

  DATA:
    ls_node             TYPE zaj_hr_org_tree_s,
    ls_org_id           TYPE ty_org_id,
    ls_frontier         TYPE ty_frontier,
    ls_parent_frontier  TYPE ty_frontier,
    ls_relationship     TYPE ty_relationship,
    ls_parent           TYPE ty_parent,
    ls_existing_parent  TYPE ty_parent,
    ls_text             TYPE ty_org_text,
    ls_account          TYPE ty_account_assignment,
    ls_effective        TYPE ty_effective_assignment,
    ls_parent_effective TYPE ty_effective_assignment.

*-----------------------------------------------------------------------
* Initialisation
*-----------------------------------------------------------------------
  CLEAR et_org_tree.
  CLEAR:
    lt_nodes,
    lt_all_org_ids,
    lt_missing_ids,
    lt_visited,
    lt_frontier,
    lt_next_frontier,
    lt_relationships,
    lt_parent_map,
    lt_text_raw,
    lt_text_by_id,
    lt_account_raw,
    lt_account_by_id,
    lt_effective_by_id.

*-----------------------------------------------------------------------
* Validate and normalise input
*-----------------------------------------------------------------------
  IF iv_begda IS NOT INITIAL
     AND iv_endda IS NOT INITIAL
     AND iv_begda > iv_endda.

    RAISE invalid_date_range.

  ENDIF.

  lv_root_org = iv_root_org.

  IF lv_root_org IS INITIAL.
    lv_root_org = gc_default_root.
  ENDIF.

*-----------------------------------------------------------------------
* Snapshot-date rule:
*
* 1. IV_ENDDA when supplied
* 2. Otherwise IV_BEGDA
* 3. Otherwise current date
*
* The function returns one row per organisation and therefore represents
* a hierarchy snapshot, not multiple historical validity periods.
*-----------------------------------------------------------------------
  IF iv_endda IS NOT INITIAL.
    lv_keydate = iv_endda.
  ELSEIF iv_begda IS NOT INITIAL.
    lv_keydate = iv_begda.
  ELSE.
    lv_keydate = sy-datum.
  ENDIF.

*-----------------------------------------------------------------------
* Validate root organisation
*
* Language is intentionally not included here. The organisation may exist
* even when no text has been maintained in the logon language.
*-----------------------------------------------------------------------
  CLEAR lv_root_exists.

  SELECT SINGLE objid
    INTO lv_root_exists
    FROM hrp1000
   WHERE plvar = gc_plvar
     AND otype = gc_otype_org
     AND objid = lv_root_org
     AND istat = gc_istat_active
     AND begda <= lv_keydate
     AND endda >= lv_keydate.

  IF sy-subrc <> 0.
    RAISE root_org_not_found.
  ENDIF.

*-----------------------------------------------------------------------
* Create root node
*-----------------------------------------------------------------------
  CLEAR ls_node.

  ls_node-org_unit_id = lv_root_org.
  CLEAR ls_node-parent_org_unit_id.
  ls_node-level = 0.

  APPEND ls_node TO lt_nodes.

*-----------------------------------------------------------------------
* Register root in supporting lookup tables
*-----------------------------------------------------------------------
  CLEAR ls_org_id.
  ls_org_id-objid = lv_root_org.

  INSERT ls_org_id INTO TABLE lt_visited.
  APPEND ls_org_id TO lt_all_org_ids.

  CLEAR ls_frontier.
  ls_frontier-org_unit_id = lv_root_org.
  ls_frontier-level       = 0.

  INSERT ls_frontier INTO TABLE lt_frontier.

  CLEAR ls_parent.
  ls_parent-objid = lv_root_org.
  CLEAR ls_parent-parent_objid.

  INSERT ls_parent INTO TABLE lt_parent_map.

*-----------------------------------------------------------------------
* Build hierarchy breadth-first
*
* One relationship query is executed per hierarchy level, rather than one
* query per organisation.
*-----------------------------------------------------------------------
  WHILE lt_frontier IS NOT INITIAL.

    CLEAR:
      lt_relationships,
      lt_next_frontier.

*---------------------------------------------------------------------
* Read children of every organisation in the current level
*---------------------------------------------------------------------
    SELECT objid
           sobid
      INTO TABLE lt_relationships
      FROM hrp1001
      FOR ALL ENTRIES IN lt_frontier
     WHERE plvar = gc_plvar
       AND otype = gc_otype_org
       AND objid = lt_frontier-org_unit_id
       AND rsign = gc_rsign_down
       AND relat = gc_relation_org
       AND sclas = gc_otype_org
       AND istat = gc_istat_active
       AND begda <= lv_keydate
       AND endda >= lv_keydate.

    IF lt_relationships IS INITIAL.
      CLEAR lt_frontier.
      CONTINUE.
    ENDIF.

*---------------------------------------------------------------------
* Deterministic ordering and duplicate relationship removal
*---------------------------------------------------------------------
    SORT lt_relationships BY objid sobid.

    DELETE ADJACENT DUPLICATES FROM lt_relationships
      COMPARING objid sobid.

*---------------------------------------------------------------------
* Convert relationships into hierarchy nodes
*---------------------------------------------------------------------
    LOOP AT lt_relationships INTO ls_relationship.

      IF ls_relationship-sobid IS INITIAL.
        CONTINUE.
      ENDIF.

*-------------------------------------------------------------------
* Obtain parent level
*-------------------------------------------------------------------
      CLEAR ls_parent_frontier.

      READ TABLE lt_frontier
        INTO ls_parent_frontier
        WITH TABLE KEY org_unit_id = ls_relationship-objid.

      IF sy-subrc <> 0.
        RAISE inconsistent_hierarchy.
      ENDIF.

*-------------------------------------------------------------------
* Cycle and multiple-parent protection
*-------------------------------------------------------------------
      CLEAR ls_org_id.
      ls_org_id-objid = ls_relationship-sobid.

      READ TABLE lt_visited
        WITH TABLE KEY objid = ls_org_id-objid
        TRANSPORTING NO FIELDS.

      IF sy-subrc = 0.

        CLEAR ls_existing_parent.

        READ TABLE lt_parent_map
          INTO ls_existing_parent
          WITH TABLE KEY objid = ls_org_id-objid.

        IF sy-subrc <> 0
           OR ls_existing_parent-parent_objid
                <> ls_relationship-objid.

          RAISE inconsistent_hierarchy.

        ENDIF.

        CONTINUE.

      ENDIF.

*-------------------------------------------------------------------
* Create child node
*-------------------------------------------------------------------
      CLEAR ls_node.

      ls_node-org_unit_id        = ls_relationship-sobid.
      ls_node-parent_org_unit_id = ls_relationship-objid.
      ls_node-level              = ls_parent_frontier-level + 1.

      APPEND ls_node TO lt_nodes.

*-------------------------------------------------------------------
* Mark child as visited
*-------------------------------------------------------------------
      INSERT ls_org_id INTO TABLE lt_visited.
      APPEND ls_org_id TO lt_all_org_ids.

*-------------------------------------------------------------------
* Register parent relationship
*-------------------------------------------------------------------
      CLEAR ls_parent.

      ls_parent-objid        = ls_relationship-sobid.
      ls_parent-parent_objid = ls_relationship-objid.

      INSERT ls_parent INTO TABLE lt_parent_map.

*-------------------------------------------------------------------
* Queue child for the next breadth-first level
*-------------------------------------------------------------------
      CLEAR ls_frontier.

      ls_frontier-org_unit_id = ls_relationship-sobid.
      ls_frontier-level       = ls_parent_frontier-level + 1.

      INSERT ls_frontier INTO TABLE lt_next_frontier.

    ENDLOOP.

    lt_frontier = lt_next_frontier.

  ENDWHILE.

*-----------------------------------------------------------------------
* Bulk-read organisational-unit texts in the logon language
*-----------------------------------------------------------------------
  IF lt_all_org_ids IS NOT INITIAL.

    SELECT objid
           stext
           begda
           endda
           seqnr
      INTO TABLE lt_text_raw
      FROM hrp1000
      FOR ALL ENTRIES IN lt_all_org_ids
     WHERE plvar = gc_plvar
       AND otype = gc_otype_org
       AND objid = lt_all_org_ids-objid
       AND istat = gc_istat_active
       AND langu = sy-langu
       AND begda <= lv_keydate
       AND endda >= lv_keydate.

  ENDIF.

*-----------------------------------------------------------------------
* Resolve overlapping text records deterministically
*
* Latest BEGDA and highest sequence number are preferred.
*-----------------------------------------------------------------------
  SORT lt_text_raw BY
    objid
    begda DESCENDING
    endda DESCENDING
    seqnr DESCENDING.

  DELETE ADJACENT DUPLICATES FROM lt_text_raw
    COMPARING objid.

  LOOP AT lt_text_raw INTO ls_text.
    INSERT ls_text INTO TABLE lt_text_by_id.
  ENDLOOP.

*-----------------------------------------------------------------------
* Determine which objects have no text in the logon language
*-----------------------------------------------------------------------
  IF sy-langu <> gc_fallback_language.

    CLEAR lt_missing_ids.

    LOOP AT lt_all_org_ids INTO ls_org_id.

      READ TABLE lt_text_by_id
        WITH TABLE KEY objid = ls_org_id-objid
        TRANSPORTING NO FIELDS.

      IF sy-subrc <> 0.
        APPEND ls_org_id TO lt_missing_ids.
      ENDIF.

    ENDLOOP.

*---------------------------------------------------------------------
* Read English fallback texts
*---------------------------------------------------------------------
    IF lt_missing_ids IS NOT INITIAL.

      CLEAR lt_text_raw.

      SELECT objid
             stext
             begda
             endda
             seqnr
        INTO TABLE lt_text_raw
        FROM hrp1000
        FOR ALL ENTRIES IN lt_missing_ids
       WHERE plvar = gc_plvar
         AND otype = gc_otype_org
         AND objid = lt_missing_ids-objid
         AND istat = gc_istat_active
         AND langu = gc_fallback_language
         AND begda <= lv_keydate
         AND endda >= lv_keydate.

      SORT lt_text_raw BY
        objid
        begda DESCENDING
        endda DESCENDING
        seqnr DESCENDING.

      DELETE ADJACENT DUPLICATES FROM lt_text_raw
        COMPARING objid.

      LOOP AT lt_text_raw INTO ls_text.

        INSERT ls_text INTO TABLE lt_text_by_id.

      ENDLOOP.

    ENDIF.

  ENDIF.

*-----------------------------------------------------------------------
* Bulk-read direct HRP1008 account assignments
*-----------------------------------------------------------------------
  IF lt_all_org_ids IS NOT INITIAL.

    SELECT objid
           bukrs
           persa
           begda
           endda
           seqnr
      INTO TABLE lt_account_raw
      FROM hrp1008
      FOR ALL ENTRIES IN lt_all_org_ids
     WHERE plvar = gc_plvar
       AND otype = gc_otype_org
       AND objid = lt_all_org_ids-objid
       AND istat = gc_istat_active
       AND begda <= lv_keydate
       AND endda >= lv_keydate.

  ENDIF.

*-----------------------------------------------------------------------
* Validate that only one account-assignment record is effective per
* organisational unit on the requested key date.
*-----------------------------------------------------------------------
  SORT lt_account_raw BY
    objid
    begda DESCENDING
    endda DESCENDING
    seqnr DESCENDING.

  CLEAR:
    lv_previous_objid,
    lv_have_previous.

  LOOP AT lt_account_raw INTO ls_account.

    IF lv_have_previous = abap_true
       AND lv_previous_objid = ls_account-objid.

      RAISE inconsistent_account_assignment.

    ENDIF.

    lv_previous_objid = ls_account-objid.
    lv_have_previous  = abap_true.

    INSERT ls_account INTO TABLE lt_account_by_id.

  ENDLOOP.

*-----------------------------------------------------------------------
* Enrich nodes and resolve inherited company code/personnel area
*
* lt_nodes is in breadth-first order, so the parent assignment has already
* been calculated before its children are processed.
*-----------------------------------------------------------------------
  LOOP AT lt_nodes INTO ls_node.

*---------------------------------------------------------------------
* Organisational-unit name
*---------------------------------------------------------------------
    CLEAR ls_text.

    READ TABLE lt_text_by_id
      INTO ls_text
      WITH TABLE KEY objid = ls_node-org_unit_id.

    IF sy-subrc = 0.
      ls_node-org_unit_name = ls_text-stext.
    ELSE.
      CLEAR ls_node-org_unit_name.
    ENDIF.

*---------------------------------------------------------------------
* Start with inherited parent assignment
*---------------------------------------------------------------------
    CLEAR ls_effective.

    ls_effective-objid = ls_node-org_unit_id.

    IF ls_node-parent_org_unit_id IS NOT INITIAL.

      CLEAR ls_parent_effective.

      READ TABLE lt_effective_by_id
        INTO ls_parent_effective
        WITH TABLE KEY objid = ls_node-parent_org_unit_id.

      IF sy-subrc <> 0.
        RAISE inconsistent_hierarchy.
      ENDIF.

      ls_effective-bukrs = ls_parent_effective-bukrs.
      ls_effective-persa = ls_parent_effective-persa.

    ENDIF.

*---------------------------------------------------------------------
* Override inherited values with direct HRP1008 values
*---------------------------------------------------------------------
    CLEAR ls_account.

    READ TABLE lt_account_by_id
      INTO ls_account
      WITH TABLE KEY objid = ls_node-org_unit_id.

    IF sy-subrc = 0.

      IF ls_account-bukrs IS NOT INITIAL.
        ls_effective-bukrs = ls_account-bukrs.
      ENDIF.

      IF ls_account-persa IS NOT INITIAL.
        ls_effective-persa = ls_account-persa.
      ENDIF.

    ENDIF.

*---------------------------------------------------------------------
* Set effective assignment on output row
*---------------------------------------------------------------------
    ls_node-company_code   = ls_effective-bukrs.
    ls_node-personnel_area = ls_effective-persa.

*---------------------------------------------------------------------
* Save effective values for child inheritance
*---------------------------------------------------------------------
    INSERT ls_effective INTO TABLE lt_effective_by_id.

*---------------------------------------------------------------------
* Add fully enriched row to the result
*---------------------------------------------------------------------
    APPEND ls_node TO et_org_tree.

  ENDLOOP.

ENDFUNCTION.
