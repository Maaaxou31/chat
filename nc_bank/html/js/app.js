// ============================================
// GLOBAL VARIABLES
// ============================================

let currentData = null;
let currentAccount = 'personal'; // 'personal' or 'business'
let pinVisible = false;

// ============================================
// UTILITY FUNCTIONS
// ============================================

// Format money with $
function formatMoney(amount) {
    return '$' + amount.toString().replace(/\B(?=(\d{3})+(?!\\d))/g, ",");
}

// Format date
function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleDateString('fr-FR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}

// Get transaction icon
function getTransactionIcon(type) {
    const icons = {
        'deposit': '📥',
        'withdraw': '📤',
        'transfer_sent': '💸',
        'transfer_received': '💰',
        'interest': '📈'
    };
    return icons[type] || '💵';
}

// Get transaction type name
function getTransactionTypeName(type) {
    const types = {
        'deposit': 'Dépôt',
        'withdraw': 'Retrait',
        'transfer_sent': 'Virement envoyé',
        'transfer_received': 'Virement reçu',
        'interest': 'Intérêts'
    };
    return types[type] || type;
}

// Get current active account
function getCurrentAccount() {
    if (currentAccount === 'personal') {
        return currentData.personalAccount;
    } else {
        return currentData.businessAccount;
    }
}

// ============================================
// UI CONTROL FUNCTIONS
// ============================================

// Close bank UI
function closeBank() {
    $('#bank-container').fadeOut(300);
    $.post('https://nc_bank/close', JSON.stringify({}));
}

// Switch tabs
function switchTab(tabName) {
    $('.tab-content').removeClass('active');
    $('.tab-btn').removeClass('active');

    $(`#${tabName}-tab`).addClass('active');
    $(`.tab-btn[data-tab="${tabName}"]`).addClass('active');
}

// Switch account (Personal <-> Business)
function switchAccount(accountType) {
    currentAccount = accountType;

    $('.account-btn').removeClass('active');
    $(`.account-btn[data-account="${accountType}"]`).addClass('active');

    // Update UI for selected account
    updateHomeTab();
    loadTransactions();
    loadCards();
    updateAccountTab();
}

// Toggle PIN visibility
function togglePIN() {
    pinVisible = !pinVisible;
    const account = getCurrentAccount();

    if (pinVisible && account) {
        $('#home-pin').text(account.pin_code).removeClass('pin-masked');
    } else if (account) {
        $('#home-pin').text('****').addClass('pin-masked');
    }
}

// ============================================
// DATA UPDATE FUNCTIONS
// ============================================

// Update home tab with current account data
function updateHomeTab() {
    const account = getCurrentAccount();
    if (!account) return;

    $('#home-balance').text(formatMoney(account.balance));
    $('#home-cash').text(formatMoney(currentData.cash));
    $('#home-iban').text(account.iban);

    if (pinVisible) {
        $('#home-pin').text(account.pin_code).removeClass('pin-masked');
    } else {
        $('#home-pin').text('****').addClass('pin-masked');
    }

    // Load recent transactions
    displayRecentTransactions(currentData.recentTransactions);
}

// Display recent transactions
function displayRecentTransactions(transactions) {
    const list = $('#recent-transactions');
    list.empty();

    if (!transactions || transactions.length === 0) {
        list.append(`
            <div style="text-align: center; padding: 20px; color: rgba(255,255,255,0.5);">
                <p>Aucune transaction récente</p>
            </div>
        `);
        return;
    }

    transactions.forEach(transaction => {
        const isPositive = transaction.transaction_type === 'deposit' ||
                          transaction.transaction_type === 'transfer_received' ||
                          transaction.transaction_type === 'interest';

        const amountClass = isPositive ? 'positive' : 'negative';
        const amountSign = isPositive ? '+' : '-';

        list.append(`
            <div class="recent-item">
                <div class="recent-info">
                    <div class="recent-icon">${getTransactionIcon(transaction.transaction_type)}</div>
                    <div class="recent-details">
                        <h4>${getTransactionTypeName(transaction.transaction_type)}</h4>
                        <div class="recent-date">${formatDate(transaction.created_at)}</div>
                    </div>
                </div>
                <div class="recent-amount ${amountClass}">
                    ${amountSign}${formatMoney(transaction.amount)}
                </div>
            </div>
        `);
    });
}

// Load all transactions for current account
function loadTransactions() {
    const account = getCurrentAccount();
    if (!account) return;

    ESX.TriggerServerCallback('nc_bank:getTransactions', function(transactions) {
        displayAllTransactions(transactions);
    }, account.id);
}

// Display all transactions
function displayAllTransactions(transactions) {
    const list = $('#all-transactions');
    list.empty();

    if (!transactions || transactions.length === 0) {
        list.append(`
            <div style="text-align: center; padding: 40px; color: rgba(255,255,255,0.5);">
                <p style="font-size: 18px;">Aucune transaction</p>
            </div>
        `);
        return;
    }

    transactions.forEach(transaction => {
        const isPositive = transaction.transaction_type === 'deposit' ||
                          transaction.transaction_type === 'transfer_received' ||
                          transaction.transaction_type === 'interest';

        const amountClass = isPositive ? 'positive' : 'negative';
        const amountSign = isPositive ? '+' : '-';

        list.append(`
            <div class="transaction-item">
                <div class="transaction-info">
                    <div class="transaction-icon">${getTransactionIcon(transaction.transaction_type)}</div>
                    <div class="transaction-details">
                        <h4>${getTransactionTypeName(transaction.transaction_type)}</h4>
                        <div class="transaction-date">${formatDate(transaction.created_at)}</div>
                        ${transaction.description ? `<div class="transaction-description">${transaction.description}</div>` : ''}
                        ${transaction.target_iban ? `<div class="transaction-description">IBAN: ${transaction.target_iban}</div>` : ''}
                    </div>
                </div>
                <div class="transaction-amount ${amountClass}">
                    ${amountSign}${formatMoney(transaction.amount)}
                </div>
            </div>
        `);
    });
}

// Load cards for current account
function loadCards() {
    const list = $('#cards-list');
    list.empty();

    if (!currentData.cards || currentData.cards.length === 0) {
        list.append(`
            <div style="text-align: center; padding: 40px; color: rgba(255,255,255,0.5); grid-column: 1/-1;">
                <p style="font-size: 18px;">Aucune carte bancaire</p>
            </div>
        `);
        return;
    }

    // Filter cards by current account type
    const filteredCards = currentData.cards.filter(card => card.account_type === currentAccount);

    if (filteredCards.length === 0) {
        list.append(`
            <div style="text-align: center; padding: 40px; color: rgba(255,255,255,0.5); grid-column: 1/-1;">
                <p style="font-size: 18px;">Aucune carte pour ce compte</p>
            </div>
        `);
        return;
    }

    filteredCards.forEach(card => {
        const cardTypeName = card.card_type === 'debit' ? 'Carte de Débit' : 'Carte de Crédit';
        const expiryDate = card.expiry_date || '--/--';

        // Formater le numéro de carte (XXXX XXXX XXXX XXXX)
        const formattedCardNumber = card.card_number.match(/.{1,4}/g).join(' ');

        list.append(`
            <div class="bank-card">
                <div class="card-header">
                    <div class="card-chip"></div>
                    <div class="card-type">${cardTypeName}</div>
                </div>
                <div class="card-number">${formattedCardNumber}</div>
                <div class="card-footer">
                    <div class="card-info">
                        <div class="card-label">Titulaire</div>
                        <div class="card-value">${currentData.playerName}</div>
                    </div>
                    <div class="card-info">
                        <div class="card-label">Expire le</div>
                        <div class="card-value">${expiryDate}</div>
                    </div>
                    <div class="card-info">
                        <div class="card-label">CVV</div>
                        <div class="card-value">${card.cvv || '***'}</div>
                    </div>
                </div>
            </div>
        `);
    });
}

// Update account tab settings
function updateAccountTab() {
    const account = getCurrentAccount();
    if (!account) return;

    // Update account info display
    const accountTypeName = account.account_type === 'personal' ? 'Compte Personnel' : 'Compte Entreprise';
    $('#account-type-display').text(accountTypeName);
    $('#account-name-display').text(account.account_name);
    $('#account-iban-display').text(account.iban);

    if (account.created_at) {
        $('#account-created-display').text(formatDate(account.created_at));
    }

    // Show/hide settings based on account type
    if (currentAccount === 'personal') {
        $('#personal-settings').show();
        $('#business-settings').hide();
    } else {
        $('#personal-settings').hide();
        $('#business-settings').show();
        loadEmployees();
    }
}

// Load employees for business account
function loadEmployees() {
    const account = getCurrentAccount();
    if (!account || account.account_type !== 'business') return;

    ESX.TriggerServerCallback('nc_bank:getBusinessEmployees', function(employees) {
        displayEmployees(employees);
    }, account.id);
}

// Display employees
function displayEmployees(employees) {
    const list = $('#employees-list');
    list.empty();

    if (!employees || employees.length === 0) {
        list.append(`
            <div style="text-align: center; padding: 40px; color: rgba(255,255,255,0.5);">
                <p style="font-size: 16px;">Aucun employé</p>
                <p style="font-size: 14px; margin-top: 10px;">Cliquez sur "Synchroniser les employés" pour charger la liste</p>
            </div>
        `);
        return;
    }

    employees.forEach(employee => {
        const lastPayment = employee.last_payment ? formatDate(employee.last_payment) : 'Jamais payé';

        list.append(`
            <div class="employee-item">
                <div class="employee-info">
                    <h4>${employee.employee_name}</h4>
                    <div class="employee-details">
                        Grade: ${employee.job_grade_name} (${employee.job_grade}) |
                        Dernier paiement: ${lastPayment}
                    </div>
                </div>
                <div class="employee-actions">
                    <div class="employee-salary">${formatMoney(employee.salary)}</div>
                    <button class="btn btn-success" onclick="paySalary(${employee.id})">
                        💰 Payer
                    </button>
                </div>
            </div>
        `);
    });
}

// ============================================
// BANKING OPERATIONS
// ============================================

// Quick deposit
function quickDeposit() {
    const amount = parseInt($('#quick-amount').val());

    if (!amount || amount <= 0) {
        return;
    }

    const account = getCurrentAccount();
    if (!account) return;

    $.post('https://nc_bank/deposit', JSON.stringify({
        accountId: account.id,
        amount: amount
    }));

    $('#quick-amount').val('');
}

// Quick withdraw
function quickWithdraw() {
    const amount = parseInt($('#quick-amount').val());

    if (!amount || amount <= 0) {
        return;
    }

    const account = getCurrentAccount();
    if (!account) return;

    $.post('https://nc_bank/withdraw', JSON.stringify({
        accountId: account.id,
        amount: amount
    }));

    $('#quick-amount').val('');
}

// Make transfer
function makeTransfer() {
    const targetIban = $('#transfer-iban').val().trim();
    const amount = parseInt($('#transfer-amount').val());

    if (!targetIban || targetIban === '') {
        return;
    }

    if (!amount || amount <= 0) {
        return;
    }

    const account = getCurrentAccount();
    if (!account) return;

    $.post('https://nc_bank/transfer', JSON.stringify({
        accountId: account.id,
        targetIban: targetIban,
        amount: amount
    }));

    $('#transfer-iban').val('');
    $('#transfer-amount').val('');
}

// Search transactions
function searchTransactions() {
    const account = getCurrentAccount();
    if (!account) return;

    const filters = {
        minAmount: $('#filter-min-amount').val() || null,
        maxAmount: $('#filter-max-amount').val() || null,
        startDate: $('#filter-start-date').val() || null,
        endDate: $('#filter-end-date').val() || null
    };

    ESX.TriggerServerCallback('nc_bank:searchTransactions', function(transactions) {
        displayAllTransactions(transactions);
    }, account.id, filters);
}

// Reset filters
function resetFilters() {
    $('#filter-min-amount').val('');
    $('#filter-max-amount').val('');
    $('#filter-start-date').val('');
    $('#filter-end-date').val('');
    loadTransactions();
}

// Change PIN
function changePIN() {
    const oldPIN = $('#old-pin').val();
    const newPIN = $('#new-pin').val();
    const confirmPIN = $('#confirm-pin').val();

    if (!oldPIN || !newPIN || !confirmPIN) {
        return;
    }

    if (newPIN !== confirmPIN) {
        alert('Les codes PIN ne correspondent pas');
        return;
    }

    if (newPIN.length !== 4 || !/^\d+$/.test(newPIN)) {
        alert('Le code PIN doit contenir 4 chiffres');
        return;
    }

    const account = getCurrentAccount();
    if (!account) return;

    $.post('https://nc_bank/changePIN', JSON.stringify({
        accountId: account.id,
        oldPIN: oldPIN,
        newPIN: newPIN
    }));

    $('#old-pin').val('');
    $('#new-pin').val('');
    $('#confirm-pin').val('');
}

// Sync employees (business account)
function syncEmployees() {
    const account = getCurrentAccount();
    if (!account || account.account_type !== 'business') return;

    $.post('https://nc_bank/syncEmployees', JSON.stringify({
        accountId: account.id
    }));
}

// Pay salary to employee
function paySalary(employeeId) {
    const account = getCurrentAccount();
    if (!account || account.account_type !== 'business') return;

    $.post('https://nc_bank/paySalary', JSON.stringify({
        accountId: account.id,
        employeeId: employeeId
    }));
}

// ============================================
// NUI MESSAGE HANDLER
// ============================================

window.addEventListener('message', function(event) {
    const data = event.data;

    switch(data.action) {
        case 'openBank':
            currentData = data.data;
            currentAccount = 'personal';
            pinVisible = false;

            // Update header
            $('#server-name').text(currentData.serverName);
            $('#player-name').text(currentData.playerName);

            // Show/hide business account button
            if (currentData.businessAccount) {
                $('#business-btn').show();
            } else {
                $('#business-btn').hide();
            }

            // Reset to personal account
            switchAccount('personal');

            // Show bank container
            $('#bank-container').fadeIn(300);
            break;

        case 'refreshUI':
            // Refresh all data
            $.post('https://nc_bank/getFullAccountInfo', JSON.stringify({}), function(data) {
                currentData = data;
                updateHomeTab();
                loadTransactions();
                loadCards();
                updateAccountTab();
            });
            break;
    }
});

// ============================================
// DOCUMENT READY
// ============================================

$(document).ready(function() {
    // Tab navigation
    $('.tab-btn').click(function() {
        const tab = $(this).data('tab');
        switchTab(tab);
    });

    // Account selector
    $('.account-btn').click(function() {
        const account = $(this).data('account');
        switchAccount(account);
    });

    // ESC key to close
    $(document).keyup(function(e) {
        if (e.key === "Escape") {
            closeBank();
        }
    });
});

// ============================================
// ESX COMPATIBILITY
// ============================================

// Mock ESX object for NUI testing (will be replaced by actual ESX in-game)
if (typeof ESX === 'undefined') {
    window.ESX = {
        TriggerServerCallback: function(name, cb, ...args) {
            console.log('ESX Callback:', name, args);
            cb([]);
        }
    };
}
