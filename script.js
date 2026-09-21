/* ==========================================================================
   NOVA BANK - OFFICIAL JAVASCRIPT
   Interactive Menu, Loan Calculator, Counter Animations & FAQ Accordion
   ========================================================================== */

document.addEventListener('DOMContentLoaded', () => {

    // 1. MOBILE MENU TOGGLE
    const mobileBtn = document.getElementById('mobileMenuBtn');
    const navLinks = document.getElementById('navLinks');

    if (mobileBtn && navLinks) {
        mobileBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            navLinks.classList.toggle('mobile-open');
            const isOpen = navLinks.classList.contains('mobile-open');
            mobileBtn.innerHTML = isOpen ? '&#10005;' : '&#9776;';
        });

        // Close menu when clicking outside
        document.addEventListener('click', (e) => {
            if (!navLinks.contains(e.target) && !mobileBtn.contains(e.target)) {
                navLinks.classList.remove('mobile-open');
                mobileBtn.innerHTML = '&#9776;';
            }
        });
    }

    // 2. FAQ ACCORDION TOGGLE
    const faqQuestions = document.querySelectorAll('.faq-question');
    faqQuestions.forEach(question => {
        question.addEventListener('click', () => {
            const item = question.parentElement;
            const isActive = item.classList.contains('active');

            // Close all items
            document.querySelectorAll('.faq-item').forEach(i => i.classList.remove('active'));

            // Toggle current
            if (!isActive) {
                item.classList.add('active');
            }
        });
    });

    // 3. INTERACTIVE LOAN SIMULATOR (servicos.html)
    const simAmount = document.getElementById('simAmount');
    const simMonths = document.getElementById('simMonths');
    const simAmountVal = document.getElementById('simAmountVal');
    const simMonthsVal = document.getElementById('simMonthsVal');
    const simResultMonthly = document.getElementById('simResultMonthly');
    const simResultTotal = document.getElementById('simResultTotal');

    function calculateLoan() {
        if (!simAmount || !simMonths) return;

        const amount = parseFloat(simAmount.value);
        const months = parseInt(simMonths.value);
        const rate = 0.0099; // 0.99% monthly interest rate

        // Compound interest formula: M = P * (1 + i)^n
        const total = amount * Math.pow((1 + rate), months);
        const monthly = total / months;

        simAmountVal.textContent = amount.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
        simMonthsVal.textContent = `${months} meses`;
        simResultMonthly.textContent = monthly.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
        simResultTotal.textContent = total.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
    }

    if (simAmount && simMonths) {
        simAmount.addEventListener('input', calculateLoan);
        simMonths.addEventListener('input', calculateLoan);
        calculateLoan();
    }

    // 4. STATS COUNTER ANIMATION
    const counters = document.querySelectorAll('.counter');
    counters.forEach(counter => {
        const target = +counter.getAttribute('data-target');
        const count = +counter.innerText.replace(/\D/g, '');
        if (!target) return;

        const increment = target / 80;

        const updateCount = () => {
            const current = +counter.innerText.replace(/\D/g, '');
            if (current < target) {
                const nextVal = Math.ceil(current + increment);
                counter.innerText = nextVal > target ? target.toLocaleString('pt-BR') : nextVal.toLocaleString('pt-BR');
                setTimeout(updateCount, 20);
            } else {
                counter.innerText = target.toLocaleString('pt-BR');
            }
        };

        updateCount();
    });

    // 5. CONTACT FORM FEEDBACK
    const contactForm = document.getElementById('contactForm');
    const formFeedback = document.getElementById('formFeedback');

    if (contactForm && formFeedback) {
        contactForm.addEventListener('submit', (e) => {
            e.preventDefault();
            formFeedback.style.display = 'block';
            formFeedback.style.background = 'rgba(16, 185, 129, 0.15)';
            formFeedback.style.border = '1px solid #10B981';
            formFeedback.style.color = '#065F46';
            formFeedback.style.padding = '1rem';
            formFeedback.style.borderRadius = '8px';
            formFeedback.style.marginBottom = '1.5rem';
            formFeedback.innerHTML = '<strong>Mensagem enviada com sucesso!</strong> Entraremos em contato em até 24 horas.';
            contactForm.reset();
        });
    }
});
