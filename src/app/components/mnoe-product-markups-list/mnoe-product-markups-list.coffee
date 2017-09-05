#
# Mnoe product markup list
#
@App.component('mnoeProductMarkupsList', {
  templateUrl: 'app/components/mnoe-product-markups-list/mnoe-product-markups-list.html',
  bindings: {
    view: '@',
  }
  controller: ($filter, $log, MnoeProductMarkups, MnoeCurrentUser, MnoConfirm, MnoeObservables, ADMIN_ROLES, OBS_KEYS, toastr) ->
    vm = this

    vm.markups =
      editmode: []
      search: {}
      sort: "product.name"
      nbItems: 10
      offset: 0
      page: 1
      list: []
      widgetTitle: 'mnoe_admin_panel.dashboard.product_markups.widget.list.title'
      pageChangedCb: (nbItems, page) ->
        vm.markups.nbItems = nbItems
        vm.markups.page = page
        offset = (page  - 1) * nbItems
        fetchProductMarkups(nbItems, offset)

    # Manage sorting, search and pagination
    vm.callServer = (tableState) ->
      sort   = updateSort (tableState.sort)
      search = updateSearch (tableState.search)

      fetchProductMarkups(vm.markups.nbItems, vm.markups.offset, sort, search)

    # Update sorting parameters
    updateSort = (sortState = {}) ->
      sort = "product.name"
      if sortState.predicate
        sort = sortState.predicate
        if sortState.reverse
          sort += ".desc"
        else
          sort += ".asc"

      # Update markups sort
      vm.markups.sort = sort
      return sort

    # Update searching parameters
    updateSearch = (searchingState = {}) ->
      search = {}
      if searchingState.predicateObject
        for attr, value of searchingState.predicateObject
          if _.isObject(value)
            # Workaround to allow 'relation.field' type of search
            # 'product.name' search for 'a' is interpreted by Smart Table as {product: {name: 'a'}
            search[ 'where[' + attr + '.' + _.keys(value)[0] + '.like]' ] = _.values(value)[0] + '%'
          else
            search[ 'where[' + attr + '.like]' ] = value + '%'

      # Update markups sort
      vm.markups.search = search
      vm.markups.pageChangedCb(vm.markups.nbItems, 1)
      return search

    # Fetch markups
    fetchProductMarkups = (limit, offset, sort = vm.markups.sort, search = vm.markups.search) ->
      vm.markups.loading = true
      return MnoeProductMarkups.markups(limit, offset, sort, search).then(
        (response) ->
          vm.markups.totalItems = response.headers('x-total-count')
          vm.markups.list = response.data
      ).finally(-> vm.markups.loading = false)

    # Initial call and start the listeners
    fetchProductMarkups(vm.markups.nbItems, 0).then( ->
    # Notify me if a user is added
      MnoeObservables.registerCb(OBS_KEYS.markupAdded, ->
        fetchProductMarkups(vm.markups.nbItems, vm.markups.offset)
      )
      # Notify me if the list changes
      MnoeObservables.registerCb(OBS_KEYS.markupChanged, ->
        fetchProductMarkups(vm.markups.nbItems, vm.markups.offset)
      )
    )

    vm.update = (pm) ->
      MnoeProductMarkups.updateProductMarkup(pm).then(
        (response) ->
          updateSort()
          updateSearch()
          # Remove the edit mode for this user
          delete vm.editmode[pm.id]
        (error) ->
          # Display an error
          $log.error('Error while saving product markup', error)
          toastr.error('mnoe_admin_panel.dashboard.product_markups.add_markup.modal.toastr_error')
      )

    vm.remove = (pm) ->
      modalOptions =
        closeButtonText: 'mnoe_admin_panel.dashboard.product_markups.modal.remove_product_markup.cancel'
        actionButtonText: 'mnoe_admin_panel.dashboard.product_markups.modal.remove_product_markup.delete'
        headerText: 'mnoe_admin_panel.dashboard.product_markups.modal.remove_product_markup.proceed'
        bodyText: 'mnoe_admin_panel.dashboard.product_markups.modal.remove_product_markup.perform'

      MnoConfirm.showModal(modalOptions).then( ->
        MnoeProductMarkups.deleteProductMarkup(pm).then( ->
          updateSort()
          updateSearch()
          toastr.success('mnoe_admin_panel.dashboard.product_markups.modal.remove_product_markup.toastr_success')
        )
      )

    onMarkupAdded = ->
      fetchProductMarkups(vm.markups.nbItems, vm.markups.offset)

    onMarkupChanged = ->
      fetchProductMarkups(vm.markups.nbItems, vm.markups.offset)

    # Notify me if a markup is added
    MnoeObservables.registerCb(OBS_KEYS.markupAdded, onMarkupAdded)
    # Notify me if the list changes
    MnoeObservables.registerCb(OBS_KEYS.markupChanged, onMarkupChanged)

    this.$onDestroy = ->
      MnoeObservables.unsubscribe(OBS_KEYS.markupAdded, onMarkupAdded)
      MnoeObservables.unsubscribe(OBS_KEYS.markupChanged, onMarkupChanged)

    return

})
