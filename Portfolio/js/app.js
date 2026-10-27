/* ══════════════════════════════════════════════════════════════
   PureScan AI — Ultra-Premium Portfolio JavaScript v2
   Particle system, cursor spotlight, 3D tilt, scroll reveals,
   counter animations, loading screen, progress bar
   ══════════════════════════════════════════════════════════════ */

// ── Loading Screen ──
window.addEventListener('load', () => {
    const loader = document.getElementById('loader');
    setTimeout(() => {
        loader.classList.add('hidden');
        document.querySelector('.navbar')?.classList.add('fade-in');
    }, 1200);
});

// ── Scroll Progress Bar ──
window.addEventListener('scroll', () => {
    const scrollTop = document.documentElement.scrollTop;
    const docHeight = document.documentElement.scrollHeight - window.innerHeight;
    const progress = (scrollTop / docHeight) * 100;
    const bar = document.getElementById('scrollProgress');
    if (bar) bar.style.width = progress + '%';
});

// ── Cursor Spotlight ──
const cursorGlow = document.getElementById('cursorGlow');
if (cursorGlow && window.innerWidth > 768) {
    document.addEventListener('mousemove', (e) => {
        cursorGlow.style.left = e.clientX + 'px';
        cursorGlow.style.top = e.clientY + 'px';
    });
}

// ══════════════════════════════════
// PARTICLE SYSTEM
// ══════════════════════════════════
const particleCanvas = document.getElementById('particles-canvas');
if (particleCanvas) {
    const pCtx = particleCanvas.getContext('2d');
    let particles = [];
    const PARTICLE_COUNT = 60;

    function resizeParticleCanvas() {
        particleCanvas.width = window.innerWidth;
        particleCanvas.height = window.innerHeight;
    }

    resizeParticleCanvas();
    window.addEventListener('resize', resizeParticleCanvas);

    class Particle {
        constructor() {
            this.reset();
        }

        reset() {
            this.x = Math.random() * particleCanvas.width;
            this.y = Math.random() * particleCanvas.height;
            this.size = Math.random() * 2 + 0.5;
            this.speedX = (Math.random() - 0.5) * 0.3;
            this.speedY = (Math.random() - 0.5) * 0.3;
            this.opacity = Math.random() * 0.4 + 0.1;
            this.fadeSpeed = Math.random() * 0.005 + 0.002;
            this.growing = Math.random() > 0.5;
        }

        update() {
            this.x += this.speedX;
            this.y += this.speedY;

            if (this.growing) {
                this.opacity += this.fadeSpeed;
                if (this.opacity >= 0.5) this.growing = false;
            } else {
                this.opacity -= this.fadeSpeed;
                if (this.opacity <= 0.05) this.growing = true;
            }

            if (this.x < 0 || this.x > particleCanvas.width ||
                this.y < 0 || this.y > particleCanvas.height) {
                this.reset();
            }
        }

        draw() {
            pCtx.beginPath();
            pCtx.arc(this.x, this.y, this.size, 0, Math.PI * 2);
            pCtx.fillStyle = `rgba(126, 219, 166, ${this.opacity})`;
            pCtx.fill();

            // Subtle glow
            pCtx.beginPath();
            pCtx.arc(this.x, this.y, this.size * 3, 0, Math.PI * 2);
            pCtx.fillStyle = `rgba(126, 219, 166, ${this.opacity * 0.15})`;
            pCtx.fill();
        }
    }

    for (let i = 0; i < PARTICLE_COUNT; i++) {
        particles.push(new Particle());
    }

    // Draw connecting lines between nearby particles
    function drawLines() {
        for (let i = 0; i < particles.length; i++) {
            for (let j = i + 1; j < particles.length; j++) {
                const dx = particles[i].x - particles[j].x;
                const dy = particles[i].y - particles[j].y;
                const dist = Math.sqrt(dx * dx + dy * dy);

                if (dist < 150) {
                    const opacity = (1 - dist / 150) * 0.08;
                    pCtx.beginPath();
                    pCtx.moveTo(particles[i].x, particles[i].y);
                    pCtx.lineTo(particles[j].x, particles[j].y);
                    pCtx.strokeStyle = `rgba(126, 219, 166, ${opacity})`;
                    pCtx.lineWidth = 0.5;
                    pCtx.stroke();
                }
            }
        }
    }

    function animateParticles() {
        pCtx.clearRect(0, 0, particleCanvas.width, particleCanvas.height);
        particles.forEach(p => {
            p.update();
            p.draw();
        });
        drawLines();
        requestAnimationFrame(animateParticles);
    }

    animateParticles();
}

// ══════════════════════════════════
// CANVAS SCROLL SEQUENCE (Frame animation)
// ══════════════════════════════════
const canvas = document.getElementById('hero-lightpass');
const context = canvas.getContext('2d');
const frameCount = 45;
const currentFrame = index => `assests/${index.toString().padStart(2, '0')}.jpg`;

const images = [];
for (let i = 1; i <= frameCount; i++) {
    const img = new Image();
    img.src = currentFrame(i);
    images.push(img);
}

canvas.width = 1920;
canvas.height = 1080;

images[0].onload = function() {
    context.drawImage(images[0], 0, 0, canvas.width, canvas.height);
};

const updateImage = index => {
    if (images[index - 1] && images[index - 1].complete) {
        context.drawImage(images[index - 1], 0, 0, canvas.width, canvas.height);
    }
};

window.addEventListener('scroll', () => {
    const scrollTop = document.documentElement.scrollTop;
    const section = document.querySelector('.scroll-sequence');
    if (!section) return;

    const sectionTop = section.offsetTop;
    const sectionHeight = section.offsetHeight - window.innerHeight;
    let scrollFraction = (scrollTop - sectionTop) / sectionHeight;
    scrollFraction = Math.max(0, Math.min(1, scrollFraction));

    const frameIndex = Math.min(frameCount - 1, Math.floor(scrollFraction * frameCount));
    requestAnimationFrame(() => updateImage(frameIndex + 1));

    // Overlay text fades
    const step1 = document.querySelector('.step-1');
    const step2 = document.querySelector('.step-2');
    const step3 = document.querySelector('.step-3');

    if (step1 && step2 && step3) {
        step1.classList.toggle('active', scrollFraction > 0.05 && scrollFraction < 0.3);
        step2.classList.toggle('active', scrollFraction > 0.35 && scrollFraction < 0.6);
        step3.classList.toggle('active', scrollFraction > 0.65 && scrollFraction < 0.92);
    }
});

// ── Navbar Scroll State ──
window.addEventListener('scroll', () => {
    const navbar = document.getElementById('navbar');
    if (navbar) navbar.classList.toggle('scrolled', window.scrollY > 80);
});

// ── Mobile Nav Toggle ──
const navToggle = document.getElementById('navToggle');
const navLinks = document.getElementById('navLinks');

if (navToggle && navLinks) {
    navToggle.addEventListener('click', () => {
        navLinks.classList.toggle('active');
        const spans = navToggle.querySelectorAll('span');
        if (navLinks.classList.contains('active')) {
            spans[0].style.transform = 'rotate(45deg) translate(5px, 5px)';
            spans[1].style.opacity = '0';
            spans[2].style.transform = 'rotate(-45deg) translate(5px, -5px)';
        } else {
            spans.forEach(s => { s.style.transform = ''; s.style.opacity = '1'; });
        }
    });

    navLinks.querySelectorAll('a').forEach(link => {
        link.addEventListener('click', () => {
            navLinks.classList.remove('active');
            navToggle.querySelectorAll('span').forEach(s => {
                s.style.transform = '';
                s.style.opacity = '1';
            });
        });
    });
}

// ══════════════════════════════════
// SCROLL REVEAL (Intersection Observer)
// ══════════════════════════════════
const revealObserver = new IntersectionObserver(
    (entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible');
                revealObserver.unobserve(entry.target);
            }
        });
    },
    { threshold: 0.08, rootMargin: '0px 0px -50px 0px' }
);

document.querySelectorAll('.reveal, .reveal-scale').forEach(el => {
    revealObserver.observe(el);
});

// ══════════════════════════════════
// COUNTER ANIMATION
// ══════════════════════════════════
const counterObserver = new IntersectionObserver(
    (entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const el = entry.target;
                const targetCount = parseInt(el.getAttribute('data-count'));
                if (!targetCount) return;

                let current = 0;
                const duration = 2000;
                const startTime = performance.now();

                function easeOutCubic(t) { return 1 - Math.pow(1 - t, 3); }

                function step(now) {
                    const elapsed = now - startTime;
                    const progress = Math.min(elapsed / duration, 1);
                    current = Math.floor(easeOutCubic(progress) * targetCount);
                    el.innerHTML = current + '<span class="accent">+</span>';
                    if (progress < 1) requestAnimationFrame(step);
                }

                requestAnimationFrame(step);
                counterObserver.unobserve(el);
            }
        });
    },
    { threshold: 0.5 }
);

document.querySelectorAll('[data-count]').forEach(el => {
    counterObserver.observe(el);
});

// ══════════════════════════════════
// 3D TILT EFFECT ON BENTO CARDS
// ══════════════════════════════════
if (window.innerWidth > 768) {
    document.querySelectorAll('.bento-card, .testimonial-card').forEach(card => {
        card.addEventListener('mousemove', (e) => {
            const rect = card.getBoundingClientRect();
            const x = e.clientX - rect.left;
            const y = e.clientY - rect.top;
            const centerX = rect.width / 2;
            const centerY = rect.height / 2;
            const rotateX = (y - centerY) / 20;
            const rotateY = (centerX - x) / 20;

            card.style.transform = `perspective(1000px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) translateY(-4px)`;
        });

        card.addEventListener('mouseleave', () => {
            card.style.transform = '';
            card.style.transition = 'transform 0.6s cubic-bezier(0.16, 1, 0.3, 1)';
            setTimeout(() => { card.style.transition = ''; }, 600);
        });
    });
}

// ── Smooth anchor scrolling ──
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
    });
});

// ── Magnetic button effect ──
if (window.innerWidth > 768) {
    document.querySelectorAll('.btn-primary, .btn-secondary').forEach(btn => {
        btn.addEventListener('mousemove', (e) => {
            const rect = btn.getBoundingClientRect();
            const x = e.clientX - rect.left - rect.width / 2;
            const y = e.clientY - rect.top - rect.height / 2;
            btn.style.transform = `translate(${x * 0.15}px, ${y * 0.15}px) scale(1.03)`;
        });

        btn.addEventListener('mouseleave', () => {
            btn.style.transform = '';
        });
    });
}
