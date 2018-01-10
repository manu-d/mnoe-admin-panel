@App.controller 'OrganizationController', ($filter, $state, $stateParams, $uibModal, toastr, MnoeAdminConfig, MnoeOrganizations, MnoeUsers, MnoAppsInstances, MnoeProducts) ->
  'ngInject'
  vm = this

  vm.orgId = $stateParams.orgId
  vm.users = {}
  vm.hasDisconnectedApps = false
  vm.status = {}

  vm.availableBillingCurrencies = MnoeAdminConfig.availableBillingCurrencies()

  # Display user creation modal
  vm.users.createUserModal = ->
    modalInstance = $uibModal.open(
      templateUrl: 'app/views/organization/create-user-modal/create-user.html'
      controller: 'CreateUserController'
      controllerAs: 'vm'
      resolve:
        organization: vm.organization
    )
    modalInstance.result.then(
      (user) ->
        # Push user to the current list of users
        vm.organization.members.push(user)
    )

  # Get the organization
  MnoeOrganizations.get($stateParams.orgId).then(
    (response) ->
      vm.organization = response.data.plain()
      vm.organization.invoices = $filter('orderBy')(vm.organization.invoices, '-started_at')
      vm.updateStatus()
  )

  vm.freezeOrganization = ->
    MnoeOrganizations.freeze(vm.organization).then(
      (response) ->
        toastr.success("mnoe_admin_panel.dashboard.organization.update_organization.toastr_success", {extraData: { name: vm.organization.name}})
        angular.copy(response.data.plain().organization, vm.organization)
      (error) ->
        toastr.error("mnoe_admin_panel.dashboard.organization.update_organization.toastr_error")
        $log.error("An error occurred:", error)
    )

  vm.unfreezeOrganization = ->
    MnoeOrganizations.unfreeze(vm.organization).then(
      (response) ->
        toastr.success("mnoe_admin_panel.dashboard.organization.update_organization.toastr_success", {extraData: { name: vm.organization.name}})
        angular.copy(response.data.plain().organization, vm.organization)
      (error) ->
        toastr.error("mnoe_admin_panel.dashboard.organization.update_organization.toastr_error")
        $log.error("An error occurred:", error)
    )

  vm.updateStatus = ->
    vm.status = {}
    _.map(vm.organization.active_apps,
      (app) ->
        vm.status[app.nid] = MnoAppsInstances.connectionStatus(app)
    )
    # Check if some apps are not connected
    vm.hasDisconnectedApps = !_.isEqual(_.uniq(_.values(vm.status)), [1])

  vm.updateOrganization = ->
    vm.editmode = false
    vm.isSaving = true
    MnoeOrganizations.update(vm.organization).then(
      (response) ->
        toastr.success("mnoe_admin_panel.dashboard.organization.update_organization.toastr_success", {extraData: { name: vm.organization.name}})
        vm.organization = response.data.organization
      (error) ->
        toastr.error("mnoe_admin_panel.dashboard.organization.update_organization.toastr_error")
        $log.error("An error occurred while updating staff:", error)
    ).finally(-> vm.isSaving = false)

  vm.resetBillingCurrency = ->
    vm.organization.billing_currency = null
    vm.updateOrganization()

  vm.openSelectProductModal = () ->
    vm.isLoadingProducts = true
    modalInstance = $uibModal.open(
      component: 'mnoProductSelectorModal'
      backdrop: 'static'
      size: 'lg'
      resolve:
        products: -> MnoeProducts.list().finally(-> vm.isLoadingProducts = false)
        multiple: -> false
    )
    modalInstance.result.then(
      (product) ->
        $state.go('dashboard.provisioning.order', {nid: product.nid, orgId: vm.organization.id})
    )

  # Add app modal
  vm.openAddAppModal = () ->
    modalInstance = $uibModal.open(
      templateUrl: 'app/views/organization/add-app-modal/add-app-modal.html'
      controller: 'AddAppModalCtrl'
      controllerAs: 'vm'
      backdrop: 'static'
      windowClass: 'add-app-modal'
      size: 'lg'
      resolve:
        organization: vm.organization
    )
    modalInstance.result.then(
      (organization) ->
        vm.organization = angular.copy(organization)
        vm.updateStatus()
    )

  # Remove app modal
  vm.openRemoveAppModal = (app, index) ->
    modalInstance = $uibModal.open(
      templateUrl: 'app/views/organization/remove-app-modal/remove-app-modal.html'
      controller: 'RemoveAppModalCtrl'
      controllerAs: 'vm'
      backdrop: 'static'
      windowClass: 'remove-app-modal'
      size: 'md'
      resolve:
        app: app
    )
    modalInstance.result.then(
      (result) ->
        # If the user decide to remove the app
        if result
          vm.organization.active_apps.splice(index, 1)
          vm.updateStatus()
    )

  return vm
