let currentData = null;

// Format numbers with commas
function formatMoney(amount) {
    return '$' + amount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
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
        'interest': '📈',
        'savings_deposit': '🏦',
        'savings_withdraw': '🏦'
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
        'interest': 'Intérêts',
        'savings_deposit': 'Dépôt épargne',
        'savings_withdraw': 'Retrait épargne'
    };
    return types[type] || type;
}

// Close bank UI
function closeBank() {
    $('#bank-container').fadeOut(300);
    $.post('https://nc_bank/close', JSON.stringify({}));
}

// Switch sections
function switchSection(sectionName) {
    $('.section').removeClass('active');
    $('.nav-item').removeClass('active');

    $(`#${sectionName}-section`).addClass('active');
    $(`.nav-item[data-section="${sectionName}"]`).addClass('active');
}

// Deposit money
function deposit() {
    const amount = parseInt($('#deposit-amount').val());

    if (!amount || amount <= 0) {
        return;
    }

    $.post('https://nc_bank/deposit', JSON.stringify({
        amount: amount
    }));

    $('#deposit-amount').val('');
}

// Withdraw money
function withdraw() {
    const amount = parseInt($('#withdraw-amount').val());

    if (!amount || amount <= 0) {
        return;
    }

    $.post('https://nc_bank/withdraw', JSON.stringify({
        amount: amount
    }));

    $('#withdraw-amount').val('');
}

// Transfer money
function transfer() {
    const target = parseInt($('#transfer-target').val());
    const amount = parseInt($('#transfer-amount').val());

    if (!target || !amount || amount <= 0) {
        return;
    }

    $.post('https://nc_bank/transfer', JSON.stringify({
        target: target,
        amount: amount
    }));

    $('#transfer-amount').val('');
}

// Load online players for transfer
function loadOnlinePlayers() {
    $.post('https://nc_bank/getOnlinePlayers', JSON.stringify({}), function(players) {
        const select = $('#transfer-target');
        select.empty();

        if (players.length === 0) {
            select.append('<option value="">Aucun joueur en ligne</option>');
        } else {
            select.append('<option value="">Sélectionner un joueur</option>');
            players.forEach(player => {
                select.append(`<option value="${player.id}">${player.name}</option>`);
            });
        }
    });
}

// Create savings account
function createSavingsAccount() {
    const name = prompt('Nom du compte d\'épargne:');

    if (name && name.trim() !== '') {
        $.post('https://nc_bank/createSavingsAccount', JSON.stringify({
            name: name
        }));
    }
}

// Savings deposit
function savingsDeposit(accountId) {
    const amount = prompt('Montant à déposer:');

    if (amount && parseInt(amount) > 0) {
        $.post('https://nc_bank/savingsDeposit', JSON.stringify({
            accountId: accountId,
            amount: parseInt(amount)
        }));
    }
}

// Savings withdraw
function savingsWithdraw(accountId) {
    const amount = prompt('Montant à retirer:');

    if (amount && parseInt(amount) > 0) {
        $.post('https://nc_bank/savingsWithdraw', JSON.stringify({
            accountId: accountId,
            amount: parseInt(amount)
        }));
    }
}

// Delete savings account
function deleteSavingsAccount(accountId) {
    if (confirm('Êtes-vous sûr de vouloir supprimer ce compte d\'épargne?')) {
        $.post('https://nc_bank/deleteSavingsAccount', JSON.stringify({
            accountId: accountId
        }));
    }
}

// Refresh history
function refreshHistory() {
    $.post('https://nc_bank/refreshTransactions', JSON.stringify({}), function(transactions) {
        displayTransactions(transactions);
    });
}

// Display transactions
function displayTransactions(transactions) {
    const list = $('#transactions-list');
    list.empty();

    if (transactions.length === 0) {
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
                        ${transaction.description ? `<div class="transaction-date">${transaction.description}</div>` : ''}
                    </div>
                </div>
                <div class="transaction-amount ${amountClass}">
                    ${amountSign}${formatMoney(transaction.amount)}
                </div>
            </div>
        `);
    });
}

// Display savings accounts
function displaySavings(savings) {
    const list = $('#savings-list');
    list.empty();

    if (savings.length === 0) {
        list.append(`
            <div style="text-align: center; padding: 40px; color: rgba(255,255,255,0.5); grid-column: 1/-1;">
                <p style="font-size: 18px;">Aucun compte d'épargne</p>
            </div>
        `);
        return;
    }

    savings.forEach(account => {
        list.append(`
            <div class="savings-card">
                <h3>${account.account_name}</h3>
                <div class="savings-balance">${formatMoney(account.balance)}</div>
                <div style="color: rgba(255,255,255,0.6); font-size: 12px; margin-bottom: 10px;">
                    Taux d'intérêt: ${account.interest_rate}%
                </div>
                <div class="savings-actions">
                    <button class="btn btn-primary" onclick="savingsDeposit(${account.id})">Déposer</button>
                    <button class="btn btn-danger" onclick="savingsWithdraw(${account.id})">Retirer</button>
                </div>
                <button class="btn btn-secondary" style="width: 100%; margin-top: 10px;" onclick="deleteSavingsAccount(${account.id})">Supprimer</button>
            </div>
        `);
    });
}

// Update preview balances
function updatePreviews() {
    if (!currentData) return;

    $('#cash-preview').text(formatMoney(currentData.account.cash));
    $('#current-balance-preview').text(formatMoney(currentData.account.balance));

    const depositAmount = parseInt($('#deposit-amount').val()) || 0;
    const withdrawAmount = parseInt($('#withdraw-amount').val()) || 0;

    $('#new-balance-preview').text(formatMoney(currentData.account.balance + depositAmount));
    $('#new-balance-withdraw-preview').text(formatMoney(currentData.account.balance - withdrawAmount));
}

// Calculate total savings
function calculateTotalSavings() {
    if (!currentData || !currentData.savings) return 0;
    return currentData.savings.reduce((total, account) => total + account.balance, 0);
}

// Update time display
function updateTime() {
    const now = new Date();
    const hours = now.getHours() % 12 || 12;
    const minutes = now.getMinutes().toString().padStart(2, '0');
    const ampm = now.getHours() >= 12 ? 'PM' : 'AM';
    $('#server-time').text(`${hours}:${minutes} ${ampm}`);
}

// Display recent transactions (top 3)
function displayRecentTransactions(transactions) {
    const list = $('#recent-transactions-list');
    list.empty();

    const recent = transactions.slice(0, 3);

    if (recent.length === 0) {
        list.append('<p style="color: rgba(255,255,255,0.5); text-align: center; padding: 20px;">Aucune transaction récente</p>');
        return;
    }

    recent.forEach(transaction => {
        const isPositive = transaction.transaction_type === 'deposit' ||
                          transaction.transaction_type === 'transfer_received' ||
                          transaction.transaction_type === 'interest';

        const amountClass = isPositive ? 'positive' : 'negative';
        const amountSign = isPositive ? '+' : '-';

        list.append(`
            <div class="transaction-item">
                <div class="transaction-icon">${getTransactionIcon(transaction.transaction_type)}</div>
                <div class="transaction-info">
                    <div class="transaction-title">${getTransactionTypeName(transaction.transaction_type)}</div>
                    <div class="transaction-date">${formatDate(transaction.created_at)}</div>
                </div>
                <div class="transaction-amount ${amountClass}">${amountSign}${formatMoney(transaction.amount)}</div>
            </div>
        `);
    });
}

// NUI Messages
window.addEventListener('message', function(event) {
    const data = event.data;

    switch(data.action) {
        case 'openBank':
            currentData = data.data;
            $('#server-name').text(currentData.account.serverName);
            $('#account-name').text(currentData.account.playerName);
            $('#balance-amount').text(formatMoney(currentData.account.balance));
            $('#cash-amount').text(formatMoney(currentData.account.cash));
            $('#savings-total-balance').text(formatMoney(calculateTotalSavings()));

            displayTransactions(currentData.transactions);
            displayRecentTransactions(currentData.transactions);
            displaySavings(currentData.savings);
            loadOnlinePlayers();
            updatePreviews();
            updateTime();

            $('#bank-container').fadeIn(300);
            break;

        case 'updateBalance':
            if (currentData) {
                currentData.account.balance = data.balance;
                currentData.account.cash = data.cash;
            }
            $('#balance-amount').text(formatMoney(data.balance));
            $('#cash-amount').text(formatMoney(data.cash));
            updatePreviews();
            break;

        case 'updateSavings':
            if (currentData) {
                currentData.savings = data.savings;
            }
            displaySavings(data.savings);
            $('#savings-total-balance').text(formatMoney(calculateTotalSavings()));
            break;
    }
});

// Navigation
$(document).ready(function() {
    $('.nav-item').click(function() {
        const section = $(this).data('section');
        switchSection(section);
    });

    // ESC key to close
    $(document).keyup(function(e) {
        if (e.key === "Escape") {
            closeBank();
        }
    });

    // Update previews when amounts change
    $('#deposit-amount, #withdraw-amount').on('input', function() {
        updatePreviews();
    });

    // Update time every second
    setInterval(updateTime, 1000);
});
