"use client";

import React, { useState, useEffect, useRef, useCallback } from "react";
import Image from "next/image";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import {
  Menu,
  X,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  Heart,
  Clock,
  MapPin,
  Phone,
  ExternalLink,
  Star,
  Users,
} from "lucide-react";

const NAV_LINKS = [
  { label: "Home", href: "hero" },
  { label: "About", href: "about" },
  { label: "Menu", href: "menu" },
  { label: "Gallery", href: "gallery" },
  { label: "Contact", href: "contact" },
];

const GALLERY_ITEMS = [
  { label: "Street Tacos", image: "https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?w=600&h=800&fit=crop" },
  { label: "Signature Margarita", image: "https://images.unsplash.com/photo-1556855810-ac404aa91e85?w=600&h=400&fit=crop" },
  { label: "Our Dining Room", image: "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=600&h=400&fit=crop" },
  { label: "Fresh Guacamole", image: "https://images.unsplash.com/photo-1600891964092-4316c288032e?w=600&h=800&fit=crop" },
  { label: "Enchiladas Suizas", image: "https://images.unsplash.com/photo-1534352956036-cd81e27dd615?w=600&h=400&fit=crop" },
  { label: "The Bar", image: "https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=600&h=800&fit=crop" },
  { label: "Churros", image: "https://images.unsplash.com/photo-1624371414361-e670246e0a04?w=600&h=400&fit=crop" },
  { label: "Patio Seating", image: "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=600&h=400&fit=crop" },
  { label: "Mole Poblano", image: "https://images.unsplash.com/photo-1615870216519-2f9fa575fa5c?w=600&h=800&fit=crop" },
  { label: "Craft Cocktails", image: "https://images.unsplash.com/photo-1551538827-9c037cb4f32a?w=600&h=400&fit=crop" },
  { label: "Family Feast", image: "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=600&h=400&fit=crop" },
  { label: "Live Music Night", image: "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600&h=400&fit=crop" },
];

const HOURS = [
  { day: "Tuesday", time: "11:00 AM – 10:00 PM" },
  { day: "Wednesday", time: "11:00 AM – 10:00 PM" },
  { day: "Thursday", time: "11:00 AM – 10:00 PM" },
  { day: "Friday", time: "11:00 AM – 11:00 PM" },
  { day: "Saturday", time: "11:00 AM – 11:00 PM" },
  { day: "Sunday", time: "Closed" },
  { day: "Monday", time: "Closed" },
];

function DecorativeDivider() {
  return (
    <div className="flex items-center justify-center py-8 px-4">
      <div className="h-px flex-1 max-w-32 bg-gradient-to-r from-transparent to-amber-400" />
      <div className="mx-4 flex items-center gap-2">
        <div className="w-2 h-2 rotate-45 bg-teal-600" />
        <div className="w-3 h-3 rotate-45 bg-amber-500" />
        <Star className="w-5 h-5 text-teal-600 fill-teal-600" />
        <div className="w-3 h-3 rotate-45 bg-amber-500" />
        <div className="w-2 h-2 rotate-45 bg-teal-600" />
      </div>
      <div className="h-px flex-1 max-w-32 bg-gradient-to-l from-transparent to-amber-400" />
    </div>
  );
}

export default function LosTulesRestaurant() {
  const [scrolled, setScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [activeSection, setActiveSection] = useState("hero");
  const [lightboxOpen, setLightboxOpen] = useState(false);
  const [lightboxIndex, setLightboxIndex] = useState(0);
  const [heroVisible, setHeroVisible] = useState(false);
  const [visibleSections, setVisibleSections] = useState<Record<string, boolean>>({});
  const [galleryVisible, setGalleryVisible] = useState<Record<number, boolean>>({});

  const sectionRefs = useRef<Record<string, HTMLElement | null>>({});
  const galleryRefs = useRef<(HTMLElement | null)[]>([]);

  useEffect(() => {
    const timer = setTimeout(() => setHeroVisible(true), 100);
    return () => clearTimeout(timer);
  }, []);

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 80);
      const sections = NAV_LINKS.map((l) => l.href);
      let current = "hero";
      for (const id of sections) {
        const el = sectionRefs.current[id];
        if (el) {
          const rect = el.getBoundingClientRect();
          if (rect.top <= 120) current = id;
        }
      }
      setActiveSection(current);
    };
    window.addEventListener("scroll", handleScroll, { passive: true });
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            const id = entry.target.getAttribute("data-section");
            if (id) setVisibleSections((prev) => ({ ...prev, [id]: true }));
          }
        });
      },
      { threshold: 0.15 }
    );
    const elements = document.querySelectorAll("[data-section]");
    elements.forEach((el) => observer.observe(el));
    return () => observer.disconnect();
  }, []);

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            const idx = entry.target.getAttribute("data-gallery-index");
            if (idx !== null) setGalleryVisible((prev) => ({ ...prev, [Number(idx)]: true }));
          }
        });
      },
      { threshold: 0.1 }
    );
    galleryRefs.current.forEach((el) => {
      if (el) observer.observe(el);
    });
    return () => observer.disconnect();
  }, []);

  useEffect(() => {
    document.body.style.overflow = lightboxOpen ? "hidden" : "";
    return () => { document.body.style.overflow = ""; };
  }, [lightboxOpen]);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (!lightboxOpen) return;
      if (e.key === "Escape") setLightboxOpen(false);
      if (e.key === "ArrowLeft") setLightboxIndex((p) => (p - 1 + GALLERY_ITEMS.length) % GALLERY_ITEMS.length);
      if (e.key === "ArrowRight") setLightboxIndex((p) => (p + 1) % GALLERY_ITEMS.length);
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [lightboxOpen]);

  const scrollToSection = useCallback((id: string) => {
    const el = sectionRefs.current[id];
    if (el) el.scrollIntoView({ behavior: "smooth" });
    setMobileMenuOpen(false);
  }, []);

  const setSectionRef = useCallback(
    (id: string) => (el: HTMLElement | null) => { sectionRefs.current[id] = el; },
    []
  );

  return (
    <div className="min-h-screen bg-stone-50 font-sans">
      {/* NAVIGATION */}
      <nav className={`fixed top-0 left-0 right-0 z-50 transition-all duration-500 ${scrolled ? "bg-stone-900/95 backdrop-blur-md shadow-lg shadow-stone-900/20" : "bg-transparent"}`}>
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16 lg:h-20">
            <button onClick={() => scrollToSection("hero")} className="flex items-center gap-2 group">
              <Image 
                src="/Los_Tules_logo_VERT.png?v=1"
                alt="Los Tules Logo" 
                width={80} 
                height={80}
                className="w-20 h-20 object-contain hover:scale-110 transition-transform duration-300"
              />
            </button>
            <div className="hidden md:flex items-center gap-1">
              {NAV_LINKS.map((link) => (
                <button key={link.href} onClick={() => scrollToSection(link.href)} className={`px-4 py-2 text-sm font-medium rounded-full transition-all duration-300 ${activeSection === link.href ? "text-amber-400 bg-white/10" : scrolled ? "text-stone-300 hover:text-amber-400 hover:bg-white/5" : "text-white/80 hover:text-white hover:bg-white/10"}`}>
                  {link.label}
                </button>
              ))}
            </div>
            <button onClick={() => setMobileMenuOpen(true)} className="md:hidden p-2 rounded-lg text-white hover:bg-white/10 transition-colors" aria-label="Open menu">
              <Menu className="w-6 h-6" />
            </button>
          </div>
        </div>
      </nav>

      {/* MOBILE MENU */}
      <div className={`fixed inset-0 z-[60] transition-all duration-500 ${mobileMenuOpen ? "visible" : "invisible"}`}>
        <div className={`absolute inset-0 bg-stone-900/98 backdrop-blur-lg transition-opacity duration-500 ${mobileMenuOpen ? "opacity-100" : "opacity-0"}`} />
        <div className={`relative h-full flex flex-col items-center justify-center transition-all duration-500 ${mobileMenuOpen ? "opacity-100 scale-100" : "opacity-0 scale-95"}`}>
          <button onClick={() => setMobileMenuOpen(false)} className="absolute top-5 right-5 p-2 text-stone-400 hover:text-white transition-colors" aria-label="Close menu">
            <X className="w-8 h-8" />
          </button>
          <div className="flex flex-col items-center gap-6">
            <Image 
              src="/Los_Tules_logo_VERT.png?v=3"
              alt="Los Tules Logo" 
              width={80} 
              height={80}
              className="w-28 h-28 object-contain mb-4"
            />
            {NAV_LINKS.map((link, i) => (
              <button key={link.href} onClick={() => scrollToSection(link.href)} className={`text-2xl font-medium transition-all duration-300 ${activeSection === link.href ? "text-amber-400" : "text-stone-300 hover:text-white"}`} style={{ transitionDelay: mobileMenuOpen ? `${i * 75}ms` : "0ms", transform: mobileMenuOpen ? "translateY(0)" : "translateY(20px)", opacity: mobileMenuOpen ? 1 : 0 }}>
                {link.label}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* HERO */}
      <section ref={setSectionRef("hero")} className="relative min-h-screen flex items-center justify-center overflow-hidden">
        <div className="absolute inset-0">
          <img src="https://images.unsplash.com/photo-1613514785940-daed07799d9b?w=1920&h=1080&fit=crop" alt="Colorful Mexican food spread" className="w-full h-full object-cover" />
          <div className="absolute inset-0 bg-gradient-to-b from-stone-900/70 via-stone-900/50 to-stone-900/80" />
        </div>
        <div className="absolute inset-0 opacity-5" style={{ backgroundImage: "radial-gradient(circle, rgba(255,255,255,0.8) 1px, transparent 1px)", backgroundSize: "30px 30px" }} />
        <div className="relative z-10 text-center px-4 max-w-4xl mx-auto">
          <div className={`transition-all duration-1000 ${heroVisible ? "opacity-100 translate-y-0" : "opacity-0 translate-y-8"}`}>
            <div className="inline-flex items-center justify-center mb-8">
              <Image 
                src="/Los_Tules_logo_VERT.png"
                alt="Los Tules Logo" 
                width={400} 
                height={400}
                className="w-90 h-90 sm:w-96 sm:h-96 object-contain drop-shadow-lg"
              />
            </div>
          </div>
          <h1 className={`text-center text-3xl sm:text-2xl md:text-5xl lg:text-6xl font-bold text-white mb-6 transition-all duration-1000 delay-200 ${heroVisible ? "opacity-100 translate-y-0" : "opacity-0 translate-y-8"}`} style={{ fontFamily: "Georgia, serif" }}>
            Los Tules
          </h1>
          <h1 className={`text-center text-1xl sm:text-1xl md:text-2xl lg:text-3xl font-bold text-white mb-6 transition-all duration-1000 delay-200 ${heroVisible ? "opacity-100 translate-y-0" : "opacity-0 translate-y-8"}`} style={{ fontFamily: "Georgia, serif" }}>
            Restaurante & Cantina
          </h1>
          <div className={`w-24 h-1 bg-gradient-to-r from-amber-400 via-orange-500 to-teal-500 mx-auto mb-6 rounded-full transition-all duration-1000 delay-300 ${heroVisible ? "opacity-100 scale-x-100" : "opacity-0 scale-x-0"}`} />
          <p className={`text-lg sm:text-xl md:text-2xl text-amber-100/80 font-light max-w-2xl mx-auto mb-10 leading-relaxed transition-all duration-1000 delay-500 ${heroVisible ? "opacity-100 translate-y-0" : "opacity-0 translate-y-8"}`} style={{ fontFamily: "Georgia, serif" }}>
            Authentic Mexican Flavor in the Heart of Kansas City
          </p>
          <div className={`flex flex-col sm:flex-row items-center justify-center gap-4 transition-all duration-1000 delay-700 ${heroVisible ? "opacity-100 translate-y-0" : "opacity-0 translate-y-8"}`}>
            <Button size="lg" className="bg-teal-600 hover:bg-teal-700 text-white px-8 py-6 text-lg rounded-full shadow-lg shadow-teal-900/30 transition-all duration-300 hover:scale-105 hover:shadow-xl" onClick={() => window.open("https://los-tules-menu-files.s3.amazonaws.com/los-tules-menu2026.pdf", "_blank")}>
              View Our Menu <ExternalLink className="w-5 h-5 ml-2" />
            </Button>
            <Button size="lg" variant="outline" className="border-2 border-amber-200/40 text-amber-100 hover:bg-amber-200/10 hover:border-amber-200/60 px-8 py-6 text-lg rounded-full transition-all duration-300 hover:scale-105 bg-transparent" onClick={() => scrollToSection("contact")}>
              <MapPin className="w-5 h-5 mr-2" /> Find Us
            </Button>
          </div>
        </div>
        <button onClick={() => scrollToSection("about")} className={`absolute bottom-8 left-1/2 -translate-x-1/2 text-white/50 hover:text-white/80 transition-all duration-1000 delay-1000 ${heroVisible ? "opacity-100" : "opacity-0"}`} aria-label="Scroll down">
          <ChevronDown className="w-8 h-8 animate-bounce" />
        </button>
      </section>

      <DecorativeDivider />

      {/* ABOUT */}
      <section ref={setSectionRef("about")} className="py-20 lg:py-32 bg-stone-50" data-section="about">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid lg:grid-cols-2 gap-12 lg:gap-20 items-center">
            <div className={`transition-all duration-1000 ${visibleSections["about"] ? "opacity-100 translate-x-0" : "opacity-0 -translate-x-12"}`}>
              <div className="relative">
                <div className="absolute -inset-4 bg-gradient-to-br from-amber-200 to-orange-200 rounded-2xl rotate-2" />
                <div className="relative aspect-[4/5] rounded-xl overflow-hidden border-4 border-amber-700/30 shadow-xl">
                  <img src="https://images.unsplash.com/photo-1552566626-52f8b828add9?w=800&h=1000&fit=crop" alt="Warm restaurant interior" className="w-full h-full object-cover" />
                  <div className="absolute inset-0 bg-gradient-to-t from-amber-900/20 to-transparent" />
                </div>
              </div>
            </div>
            <div className={`transition-all duration-1000 delay-200 ${visibleSections["about"] ? "opacity-100 translate-x-0" : "opacity-0 translate-x-12"}`}>
              <div className="w-12 h-1 bg-teal-600 rounded-full mb-6" />
              <h2 className="text-4xl lg:text-5xl font-bold text-stone-800 mb-8" style={{ fontFamily: "Georgia, serif" }}>Our Story</h2>
              <div className="space-y-5 text-stone-600 text-lg leading-relaxed">
                <p>
                  <span className="float-left text-6xl font-bold text-amber-700 mr-3 mt-1 leading-none" style={{ fontFamily: "Georgia, serif" }}>L</span>
                  os Tules is a beloved family-style Mexican restaurant nestled in the heart of Kansas City&apos;s vibrant Crossroads district, just steps from the Kauffman Center for the Performing Arts. For years, we have been a cornerstone of the community, bringing the rich flavors and warm hospitality of Mexico to the Midwest.
                </p>
                <p>Our recipes are rooted in authentic Mexican tradition — slow-cooked meats seasoned with generations-old spice blends, vibrant salsas crafted from the freshest ingredients, and signature margaritas that have become legendary among locals and visitors alike.</p>
                <p>Step inside and you&apos;ll find an atmosphere that is warm, colorful, and welcoming. Whether you&apos;re a longtime Kansas City local celebrating a family milestone or a first-time visitor exploring the Crossroads, Los Tules feels like home. Every dish tells a story, and every guest becomes part of our family.</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      <DecorativeDivider />

      {/* MENU HIGHLIGHTS */}
      <section ref={setSectionRef("menu")} className="py-20 lg:py-32 relative overflow-hidden" data-section="menu">
        <div className="absolute inset-0">
          <img src="https://images.unsplash.com/photo-1564767609342-620cb19b2357?w=1920&h=1080&fit=crop" alt="Mexican food background" className="w-full h-full object-cover" />
          <div className="absolute inset-0 bg-stone-900/90" />
        </div>
        <div className="absolute inset-0 opacity-5" style={{ backgroundImage: "radial-gradient(circle, rgba(255,255,255,0.8) 1px, transparent 1px)", backgroundSize: "40px 40px" }} />
        <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <div className={`transition-all duration-1000 ${visibleSections["menu"] ? "opacity-100 translate-y-0" : "opacity-0 translate-y-8"}`}>
            <div className="w-12 h-1 bg-teal-500 rounded-full mx-auto mb-6" />
            <h2 className="text-4xl lg:text-5xl font-bold text-amber-100 mb-6" style={{ fontFamily: "Georgia, serif" }}>Taste the Tradition</h2>
            <p className="text-stone-400 text-lg max-w-2xl mx-auto mb-16 leading-relaxed">Explore our full menu of tacos, enchiladas, burritos, mole, fresh guacamole, and craft margaritas — each dish crafted with love and authentic Mexican flavors.</p>
          </div>
          <div className="grid sm:grid-cols-3 gap-6 lg:gap-8 mb-16">
            {[
              { icon: <Star className="w-8 h-8" />, title: "Authentic Recipes", desc: "Passed down through generations", image: "https://images.unsplash.com/photo-1599974579688-8dbdd335c77f?w=400&h=300&fit=crop", delay: 0 },
              { icon: <Heart className="w-8 h-8" />, title: "Craft Margaritas", desc: "Handcrafted with fresh ingredients", image: "https://images.unsplash.com/photo-1544145945-f90425340c7e?w=400&h=300&fit=crop", delay: 150 },
              { icon: <Users className="w-8 h-8" />, title: "Family Atmosphere", desc: "Where everyone feels at home", image: "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400&h=300&fit=crop", delay: 300 },
            ].map((card, i) => (
              <div key={i} className={`transition-all duration-700 ${visibleSections["menu"] ? "opacity-100 translate-y-0" : "opacity-0 translate-y-8"}`} style={{ transitionDelay: visibleSections["menu"] ? `${card.delay + 300}ms` : "0ms" }}>
                <Card className="bg-white/5 border-amber-500/20 hover:border-amber-500/40 transition-all duration-300 hover:scale-105 hover:bg-white/10 group overflow-hidden">
                  <div className="relative h-40 overflow-hidden">
                    <img src={card.image} alt={card.title} className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500" />
                    <div className="absolute inset-0 bg-gradient-to-t from-stone-900/80 to-transparent" />
                    <div className="absolute bottom-3 left-1/2 -translate-x-1/2 w-12 h-12 rounded-full bg-stone-900/60 backdrop-blur-sm flex items-center justify-center text-amber-400 group-hover:text-teal-400 transition-colors duration-300 border border-amber-500/30">
                      {card.icon}
                    </div>
                  </div>
                  <CardContent className="p-6 text-center">
                    <h3 className="text-xl font-bold text-amber-100 mb-2" style={{ fontFamily: "Georgia, serif" }}>{card.title}</h3>
                    <p className="text-stone-400">{card.desc}</p>
                  </CardContent>
                </Card>
              </div>
            ))}
          </div>
          <div className={`transition-all duration-1000 delay-700 ${visibleSections["menu"] ? "opacity-100 translate-y-0" : "opacity-0 translate-y-8"}`}>
            <Button size="lg" className="bg-teal-600 hover:bg-teal-700 text-white px-10 py-6 text-lg rounded-full shadow-lg shadow-teal-900/40 transition-all duration-300 hover:scale-105 hover:shadow-xl" onClick={() => window.open("https://los-tules-menu-files.s3.amazonaws.com/los-tules-menu2026.pdf", "_blank")}>
              View Full Menu <ExternalLink className="w-5 h-5 ml-2" />
            </Button>
          </div>
        </div>
      </section>

      <DecorativeDivider />

      {/* GALLERY */}
      <section ref={setSectionRef("gallery")} className="py-20 lg:py-32 bg-amber-50/50" data-section="gallery">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <div className="w-12 h-1 bg-teal-600 rounded-full mx-auto mb-6" />
            <h2 className="text-4xl lg:text-5xl font-bold text-stone-800 mb-4" style={{ fontFamily: "Georgia, serif" }}>A Taste of Los Tules</h2>
            <p className="text-stone-500 text-lg max-w-xl mx-auto">Explore the vibrant flavors, warm ambiance, and unforgettable moments that await you.</p>
          </div>
          <div className="columns-2 md:columns-3 lg:columns-4 gap-4 space-y-4">
            {GALLERY_ITEMS.map((item, i) => {
              const heights = ["h-64", "h-48", "h-56", "h-72", "h-48", "h-64", "h-56", "h-48", "h-72", "h-56", "h-48", "h-64"];
              return (
                <div key={i} ref={(el) => { galleryRefs.current[i] = el; }} data-gallery-index={i} className={`break-inside-avoid cursor-pointer group transition-all duration-700 ${galleryVisible[i] ? "opacity-100 translate-y-0" : "opacity-0 translate-y-8"}`} style={{ transitionDelay: galleryVisible[i] ? `${(i % 4) * 100}ms` : "0ms" }} onClick={() => { setLightboxIndex(i); setLightboxOpen(true); }}>
                  <div className={`relative ${heights[i]} rounded-xl overflow-hidden shadow-md group-hover:shadow-xl transition-all duration-300 group-hover:scale-[1.02]`}>
                    <img src={item.image} alt={item.label} className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700" />
                    <div className="absolute inset-x-0 bottom-0 h-1/2 bg-gradient-to-t from-black/70 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                    <div className="absolute inset-x-0 bottom-0 p-4 translate-y-2 group-hover:translate-y-0 opacity-0 group-hover:opacity-100 transition-all duration-300">
                      <p className="text-white font-semibold text-sm drop-shadow-lg">{item.label}</p>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </section>

      {/* LIGHTBOX */}
      {lightboxOpen && (
        <div className="fixed inset-0 z-[70] flex items-center justify-center">
          <div className="absolute inset-0 bg-black/90 backdrop-blur-sm" onClick={() => setLightboxOpen(false)} />
          <div className="relative z-10 w-full max-w-4xl mx-4">
            <button onClick={() => setLightboxOpen(false)} className="absolute -top-12 right-0 text-white/70 hover:text-white transition-colors p-2" aria-label="Close lightbox">
              <X className="w-8 h-8" />
            </button>
            <div className="relative aspect-[4/3] rounded-2xl overflow-hidden shadow-2xl">
              <img src={GALLERY_ITEMS[lightboxIndex].image.replace(/w=\d+&h=\d+/, "w=1200&h=900")} alt={GALLERY_ITEMS[lightboxIndex].label} className="w-full h-full object-cover" />
              <div className="absolute inset-x-0 bottom-0 h-1/3 bg-gradient-to-t from-black/60 to-transparent" />
              <div className="absolute bottom-6 left-6">
                <p className="text-white text-2xl font-bold drop-shadow-lg" style={{ fontFamily: "Georgia, serif" }}>{GALLERY_ITEMS[lightboxIndex].label}</p>
                <p className="text-white/60 text-sm mt-1">{lightboxIndex + 1} of {GALLERY_ITEMS.length}</p>
              </div>
            </div>
            <button onClick={() => setLightboxIndex((lightboxIndex - 1 + GALLERY_ITEMS.length) % GALLERY_ITEMS.length)} className="absolute left-0 top-1/2 -translate-y-1/2 -translate-x-14 text-white/70 hover:text-white transition-colors p-2 hidden sm:block" aria-label="Previous">
              <ChevronLeft className="w-10 h-10" />
            </button>
            <button onClick={() => setLightboxIndex((lightboxIndex + 1) % GALLERY_ITEMS.length)} className="absolute right-0 top-1/2 -translate-y-1/2 translate-x-14 text-white/70 hover:text-white transition-colors p-2 hidden sm:block" aria-label="Next">
              <ChevronRight className="w-10 h-10" />
            </button>
            <div className="flex justify-center gap-4 mt-4 sm:hidden">
              <button onClick={() => setLightboxIndex((lightboxIndex - 1 + GALLERY_ITEMS.length) % GALLERY_ITEMS.length)} className="text-white/70 hover:text-white transition-colors p-3 bg-white/10 rounded-full">
                <ChevronLeft className="w-6 h-6" />
              </button>
              <button onClick={() => setLightboxIndex((lightboxIndex + 1) % GALLERY_ITEMS.length)} className="text-white/70 hover:text-white transition-colors p-3 bg-white/10 rounded-full">
                <ChevronRight className="w-6 h-6" />
              </button>
            </div>
          </div>
        </div>
      )}

      <DecorativeDivider />

      {/* CONTACT */}
      <section ref={setSectionRef("contact")} className="py-20 lg:py-32 bg-stone-50" data-section="contact">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <div className="w-12 h-1 bg-teal-600 rounded-full mx-auto mb-6" />
            <h2 className="text-4xl lg:text-5xl font-bold text-stone-800 mb-4" style={{ fontFamily: "Georgia, serif" }}>Visit Us</h2>
            <p className="text-stone-500 text-lg max-w-xl mx-auto">Located in the Crossroads District, near the Kauffman Center for the Performing Arts.</p>
          </div>
          <div className={`grid lg:grid-cols-2 gap-12 lg:gap-16 transition-all duration-1000 ${visibleSections["contact"] ? "opacity-100 translate-y-0" : "opacity-0 translate-y-8"}`}>
            <div className="space-y-8">
              <div className="flex items-start gap-4">
                <div className="w-12 h-12 rounded-xl bg-amber-100 flex items-center justify-center flex-shrink-0"><MapPin className="w-6 h-6 text-amber-700" /></div>
                <div>
                  <h3 className="font-bold text-stone-800 text-lg mb-1">Address</h3>
                  <p className="text-stone-600">1656 Broadway Blvd<br />Kansas City, MO 64108</p>
                </div>
              </div>
              <div className="flex items-start gap-4">
                <div className="w-12 h-12 rounded-xl bg-teal-100 flex items-center justify-center flex-shrink-0"><Phone className="w-6 h-6 text-teal-700" /></div>
                <div>
                  <h3 className="font-bold text-stone-800 text-lg mb-1">Phone</h3>
                  <a href="tel:+18164219229" className="text-teal-700 hover:text-teal-800 font-medium text-lg transition-colors">(816) 421-9229</a>
                </div>
              </div>
              <div className="flex items-start gap-4">
                <div className="w-12 h-12 rounded-xl bg-orange-100 flex items-center justify-center flex-shrink-0"><Clock className="w-6 h-6 text-orange-700" /></div>
                <div>
                  <h3 className="font-bold text-stone-800 text-lg mb-3">Hours</h3>
                  <div className="space-y-2">
                    {HOURS.map((h) => (
                      <div key={h.day} className="flex justify-between items-center gap-8">
                        <span className={`text-stone-700 font-medium ${h.time === "Closed" ? "text-stone-400" : ""}`}>{h.day}</span>
                        <span className={`text-sm ${h.time === "Closed" ? "text-red-400 font-medium" : "text-stone-500"}`}>{h.time}</span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>
            <div className="flex flex-col gap-6">
              <div className="relative flex-1 min-h-[320px] rounded-2xl overflow-hidden border-2 border-stone-200 shadow-lg">
                <img src="https://images.unsplash.com/photo-1569336415962-a4bd9f69cd83?w=800&h=600&fit=crop" alt="Kansas City Crossroads District" className="w-full h-full object-cover" />
                <div className="absolute inset-0 bg-stone-900/40 backdrop-blur-[1px]" />
                <div className="absolute inset-0 flex flex-col items-center justify-center p-6 text-center">
                  <div className="w-16 h-16 rounded-full bg-amber-600 flex items-center justify-center mb-4 shadow-lg"><MapPin className="w-8 h-8 text-white" /></div>
                  <p className="text-white font-bold text-lg mb-1 drop-shadow-lg" style={{ fontFamily: "Georgia, serif" }}>Los Tules Mexican Restaurant</p>
                  <p className="text-white/80 text-sm mb-6 drop-shadow">1656 Broadway Blvd, Kansas City, MO 64108</p>
                  <Button variant="outline" className="border-white/60 text-white hover:bg-white/20 hover:border-white rounded-full px-6 bg-white/10 backdrop-blur-sm" onClick={() => window.open("https://www.google.com/maps/search/?api=1&query=1656+Broadway+Blvd+Kansas+City+MO+64108", "_blank")}>
                    <MapPin className="w-4 h-4 mr-2" /> Get Directions
                  </Button>
                </div>
              </div>
              <div className="flex items-center justify-center gap-4">
                {[
                  { label: "Instagram", icon: <Heart className="w-5 h-5" /> },
                  { label: "Facebook", icon: <Users className="w-5 h-5" /> },
                  { label: "Yelp", icon: <Star className="w-5 h-5" /> },
                ].map((social) => (
                  <button key={social.label} className="w-12 h-12 rounded-full bg-amber-700 text-white flex items-center justify-center hover:bg-teal-600 transition-all duration-300 hover:scale-110 shadow-md" aria-label={social.label}>
                    {social.icon}
                  </button>
                ))}
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* FOOTER */}
      <footer className="relative bg-stone-900 pt-16 pb-8">
        <div className="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-amber-600 via-teal-500 to-amber-600" />
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <div className="flex items-center justify-center gap-3 mb-4">
              <Image 
                src="/Los_Tules_logo_VERT.png?v=4"
                alt="Los Tules Logo" 
                width={120} 
                height={120}
                className="w-56 h-56 object-contain"
              />
            </div>
            <p className="text-stone-400 text-lg mb-2">Los Tules Restaurante & Cantina</p>
            <p className="text-stone-500 italic max-w-md mx-auto" style={{ fontFamily: "Georgia, serif" }}>&ldquo;Bringing authentic Mexican flavor to Kansas City since day one&rdquo;</p>
          </div>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-2 sm:gap-6 mb-8">
            <p className="text-stone-400 text-sm">1656 Broadway Blvd, Kansas City, MO 64108</p>
            <span className="hidden sm:inline text-stone-600">&bull;</span>
            <a href="tel:+18164219229" className="text-stone-400 text-sm hover:text-amber-400 transition-colors">(816) 421-9229</a>
          </div>
          <div className="flex flex-wrap items-center justify-center gap-4 sm:gap-8 mb-12">
            {NAV_LINKS.map((link) => (
              <button key={link.href} onClick={() => scrollToSection(link.href)} className="text-stone-500 hover:text-amber-400 text-sm font-medium transition-colors">{link.label}</button>
            ))}
          </div>
          <div className="border-t border-stone-800 pt-8">
            <p className="text-center text-stone-600 text-sm">&copy; {new Date().getFullYear()} Los Tules Mexican Restaurant. All rights reserved.</p>
          </div>
        </div>
      </footer>
    </div>
  );
}