// Global data
let phoneAccountData = null;

// Format money
function formatMoney(amount) {
    return '$' + amount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

// Format date
function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleDateString('fr-FR', {
        day: '2-digit',
        month: '2-digit',
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
        'transfer_sent': 'Envoyé',
        'transfer_received': 'Reçu',
        'interest': 'Intérêts'
    };
    return types[type] || type;
}

// Update UI with account data
function updatePhoneBankUI(data) {
    phoneAccountData = data;

    // Update balance
    $('#phone-balance').text(formatMoney(data.balance));
    $('#phone-balance-main').text(formatMoney(data.balance));
    $('#phone-iban').text(data.iban);

    // Update transactions
    displayPhoneTransactions(data.recentTransactions);
}

// Display transactions
function displayPhoneTransactions(transactions) {
    const list = $('#phone-transactions');
    list.empty();

    if (!transactions || transactions.length === 0) {
        list.append('<div class="no-transactions">Aucune transaction</div>');
        return;
    }

    transactions.forEach(transaction => {
        const isPositive = transaction.transaction_type === 'deposit' ||
                          transaction.transaction_type === 'transfer_received' ||
                          transaction.transaction_type === 'interest';

        const amountClass = isPositive ? 'positive' : 'negative';
        const amountSign = isPositive ? '+' : '-';

        list.append(`
            <div class="phone-transaction-item">
                <div class="transaction-info-phone">
                    <div class="transaction-icon-phone">${getTransactionIcon(transaction.transaction_type)}</div>
                    <div class="transaction-details-phone">
                        <div class="transaction-type-phone">${getTransactionTypeName(transaction.transaction_type)}</div>
                        <div class="transaction-date-phone">${formatDate(transaction.created_at)}</div>
                    </div>
                </div>
                <div class="transaction-amount-phone ${amountClass}">
                    ${amountSign}${formatMoney(transaction.amount)}
                </div>
            </div>
        `);
    });
}

// Send phone transfer
function sendPhoneTransfer() {
    const phoneNumber = $('#phone-transfer-number').val().trim();
    const amount = parseInt($('#phone-transfer-amount').val());

    if (!phoneNumber || phoneNumber === '') {
        // Notification via yseries ou ESX
        return;
    }

    if (!amount || amount <= 0) {
        // Notification via yseries ou ESX
        return;
    }

    // Send to Lua
    $.post('https://' + GetParentResourceName() + '/phoneTransfer', JSON.stringify({
        phoneNumber: phoneNumber,
        amount: amount
    }), function(response) {
        if (response && response.success) {
            // Clear inputs
            $('#phone-transfer-number').val('');
            $('#phone-transfer-amount').val('');

            // Refresh data
            refreshPhoneData();
        }
    });
}

// Refresh phone data
function refreshPhoneData() {
    $.post('https://' + GetParentResourceName() + '/refreshPhoneBank', JSON.stringify({}), function(data) {
        if (data) {
            updatePhoneBankUI(data);
        }
    });
}

// NUI Message Handler
window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.app !== "nc_bank") return;

    switch(data.action) {
        case 'openPhoneBank':
            updatePhoneBankUI(data.data);
            break;

        case 'closePhoneBank':
            // Cleanup if needed
            break;

        case 'refreshPhoneBank':
            if (data.data) {
                updatePhoneBankUI(data.data);
            }
            break;
    }
});

// Get parent resource name
function GetParentResourceName() {
    let resourceName = 'nc_bank';
    if (window.location.href.includes('nui://')) {
        const match = window.location.href.match(/nui:\/\/([^\/]+)/);
        if (match) resourceName = match[1];
    }
    return resourceName;
}
