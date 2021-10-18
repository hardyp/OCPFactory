class ZCL_OCP_FACTORY definition
  public
  create public .

public section.

  class-methods RETURN_OBJECT_GIVEN
    importing
      !IT_CONTEXT_DATA type WDR_SIMPLE_NAME_VALUE_LIST
      !IT_CONSTRUCTOR_PARAMETERS type ABAP_PARMBIND_TAB optional
    changing
      !CO_OBJECT type ANY .
protected section.
private section.

  class-methods LIST_OF_IMPLEMENTING_CLASSES
    importing
      !ID_INTERFACE type SEOCLSKEY
    returning
      value(RT_CLASSES) type SEOR_IMPLEMENTING_KEYS .
ENDCLASS.



CLASS ZCL_OCP_FACTORY IMPLEMENTATION.


  METHOD list_of_implementing_classes.
*--------------------------------------------------------------------*
* Dynamic calls can only call STATIC methods
* STATIC methods cannot be redefined
* Thus, the superclass cannot implement the interface
* Only the subclasses can implement it, and thus we get a list of the
* subclasses that implement the interface, and get the associated
* superclass so it can be a default/fallback implementation
*--------------------------------------------------------------------*
* Local Variables
    DATA: lt_all_subclasses TYPE seor_inheritance_keys,
          ls_all_subclasses LIKE LINE OF lt_all_subclasses,
          lt_subclasses     TYPE seor_inheritance_keys,
          ls_subclasses     LIKE LINE OF rt_classes,
          ld_superclass     TYPE seoclskey,
          ld_current_line   TYPE sy-tabix.

    "Get any SUPERCLASS that implements the passed in interface. There may be a few.
    CALL FUNCTION 'SEO_INTERFACE_IMPLEM_GET_ALL'
      EXPORTING
        intkey       = id_interface
      IMPORTING
        impkeys      = rt_classes[]
      EXCEPTIONS
        not_existing = 1
        OTHERS       = 2.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    "Get all SUBCLASSES for the Superclass(es)
    LOOP AT rt_classes ASSIGNING FIELD-SYMBOL(<ls_classes>).
      ld_superclass = <ls_classes>-clsname.

      CALL FUNCTION 'SEO_CLASS_GET_ALL_SUBS'
        EXPORTING
          clskey             = ld_superclass
        IMPORTING
          inhkeys            = lt_subclasses[]
        EXCEPTIONS
          class_not_existing = 1
          OTHERS             = 2.

      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      "The list of subclasses comes out such that children of children
      "come at the end. Therefore we want to store the result in reverse
      "order i.e. more specialized classes first
      ld_current_line = lines( lt_subclasses[] ).

      DO."#EC CI_NESTED
        READ TABLE lt_subclasses INTO ls_subclasses INDEX ld_current_line.

        IF sy-subrc <> 0.
          EXIT."From Do-End-Do
        ENDIF.

        ls_all_subclasses-clsname    = ls_subclasses-clsname.
        ls_all_subclasses-refclsname = ls_subclasses-refclsname.
        APPEND ls_all_subclasses TO lt_all_subclasses.

        SUBTRACT 1 FROM ld_current_line.

        IF ld_current_line < 1.
          EXIT."From Do-End-Do
        ENDIF.

      ENDDO."Reading subclass list backwards

    ENDLOOP."Superclasses inheriting the Interface

    INSERT LINES OF lt_all_subclasses INTO TABLE rt_classes.

    "Delete abstract classes because they will never be able to be instantiated using CREATE OBJECT
    LOOP AT rt_classes ASSIGNING FIELD-SYMBOL(<ls_class>).
      IF CAST cl_abap_classdescr( cl_abap_typedescr=>describe_by_name( p_name = <ls_class>-clsname ) )->class_kind =
              cl_abap_classdescr=>classkind_abstract.
        DELETE rt_classes.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD return_object_given.
* Local Variables
    DATA: interface_in_reference_details TYPE REF TO cl_abap_refdescr,
          converted_interface_name       TYPE seoclskey.

    "Determine the interface of the generic reference object that was passed in
    interface_in_reference_details ?= cl_abap_refdescr=>describe_by_data( co_object ).
    DATA(interface_in_type_details) = interface_in_reference_details->get_referenced_type( ).
    DATA(interface_passed_in)       = interface_in_type_details->get_relative_name( ).
    converted_interface_name        = interface_passed_in.

    "Preconditions
    zcl_dbc=>require(
    that             = 'An Interface Reference Object is passed in'(004)
    which_is_true_if = xsdbool( interface_in_type_details->type_kind = cl_abap_typedescr=>typekind_intf ) ).

    "We now know the interface! Hurrah! We need to get a list of Z classes which implement this interface
    DATA(implementing_class_list) = list_of_implementing_classes( converted_interface_name ).

    "Dynamically create the parameters to be passed to the method
    DATA: is_the_right_class_type_given TYPE tmdir-methodname VALUE 'IS_THE_RIGHT_CLASS_TYPE_GIVEN',
          this_is_the_class_we_want     TYPE abap_bool,
          dynamic_parameters            TYPE abap_parmbind_tab.

    INSERT VALUE #(
    name = 'IT_CONTEXT_DATA'
    kind = cl_abap_objectdescr=>exporting
    value = REF #( it_context_data ) ) INTO TABLE dynamic_parameters.

    INSERT VALUE #(
    name = 'RF_YES_IT_IS'
    kind = cl_abap_objectdescr=>returning
    value = REF #( this_is_the_class_we_want ) ) INTO TABLE dynamic_parameters.

    "We are ready to rock and roll. Time to start looking for the desired class
    "Loop through all the SUBCLASSES from most specific to most generic
    LOOP AT implementing_class_list ASSIGNING FIELD-SYMBOL(<implementing_class>)
      WHERE refclsname NE converted_interface_name.

      TRY.
          CALL METHOD (<implementing_class>-clsname)=>(is_the_right_class_type_given)
            PARAMETER-TABLE dynamic_parameters.

          IF this_is_the_class_we_want = abap_true.
            IF it_constructor_parameters IS NOT SUPPLIED.
              CREATE OBJECT co_object TYPE (<implementing_class>-clsname).
            ELSE.
              CREATE OBJECT co_object TYPE (<implementing_class>-clsname)
              PARAMETER-TABLE it_constructor_parameters.
            ENDIF.
            RETURN.
          ENDIF.

        CATCH cx_sy_dyn_call_illegal_method.
          zcl_dbc=>require(
          that             = |{ 'Interface'(001) } { interface_passed_in } | &&
                             |{ 'does not implement ZIF_CREATED_VIA_OCP_FACTORY'(003) }|
          which_is_true_if = abap_false ).
      ENDTRY.

    ENDLOOP."Classes that implement the desired interface

    "If no approriate subclass has been found, then find the SUPERCLASS - default (fallback) implementation
    IF co_object IS NOT BOUND.
      LOOP AT implementing_class_list ASSIGNING <implementing_class> WHERE refclsname EQ converted_interface_name.
        IF it_constructor_parameters IS NOT SUPPLIED.
          CREATE OBJECT co_object TYPE (<implementing_class>-clsname).
        ELSE.
          CREATE OBJECT co_object TYPE (<implementing_class>-clsname)
          PARAMETER-TABLE it_constructor_parameters.
        ENDIF.
        RETURN.
      ENDLOOP.
    ENDIF.

    zcl_dbc=>require(
    that             = |{ 'Interface'(001) } { interface_passed_in } { 'needs a Default Class'(002) }|
    which_is_true_if = xsdbool( co_object IS BOUND ) ).

  ENDMETHOD.
ENDCLASS.
