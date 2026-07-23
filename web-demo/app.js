document.addEventListener('DOMContentLoaded', () => {
    const uploadZone = document.getElementById('uploadZone');
    const fileInput = document.getElementById('fileInput');
    const browseBtn = document.getElementById('browseBtn');
    const previewArea = document.getElementById('previewArea');
    const imagePreview = document.getElementById('imagePreview');
    const resetBtn = document.getElementById('resetBtn');
    const analyzeBtn = document.getElementById('analyzeBtn');
    
    const resultsCard = document.getElementById('resultsCard');
    const loader = document.getElementById('loader');
    const resultContent = document.getElementById('resultContent');

    // Trigger file input on button click
    browseBtn.addEventListener('click', () => {
        fileInput.click();
    });

    // Handle drag and drop
    uploadZone.addEventListener('dragover', (e) => {
        e.preventDefault();
        uploadZone.classList.add('dragover');
    });

    uploadZone.addEventListener('dragleave', () => {
        uploadZone.classList.remove('dragover');
    });

    uploadZone.addEventListener('drop', (e) => {
        e.preventDefault();
        uploadZone.classList.remove('dragover');
        
        if (e.dataTransfer.files.length) {
            handleFile(e.dataTransfer.files[0]);
        }
    });

    // Handle file selection
    fileInput.addEventListener('change', function() {
        if (this.files.length) {
            handleFile(this.files[0]);
        }
    });

    function handleFile(file) {
        if (!file.type.startsWith('image/')) {
            alert('Please select an image file.');
            return;
        }

        const reader = new FileReader();
        reader.onload = (e) => {
            imagePreview.src = e.target.result;
            uploadZone.classList.add('hidden');
            previewArea.classList.remove('hidden');
            
            // Reset results if a new image is loaded
            resultsCard.classList.add('hidden');
            resultContent.classList.add('hidden');
            loader.classList.add('hidden');
        };
        reader.readAsDataURL(file);
    }

    // Handle reset
    resetBtn.addEventListener('click', () => {
        uploadZone.classList.remove('hidden');
        previewArea.classList.add('hidden');
        fileInput.value = ''; // Clear input
        resultsCard.classList.add('hidden');
    });

    // Handle Analysis Simulation
    analyzeBtn.addEventListener('click', () => {
        resultsCard.classList.remove('hidden');
        loader.classList.remove('hidden');
        resultContent.classList.add('hidden');
        
        // Reset progress bar for animation effect
        const progressFill = document.querySelector('.progress-fill');
        progressFill.style.width = '0%';

        // Simulate API delay
        setTimeout(() => {
            loader.classList.add('hidden');
            resultContent.classList.remove('hidden');
            
            // Animate progress bar
            setTimeout(() => {
                progressFill.style.width = '94%';
            }, 100);
            
            // Scroll to results on mobile
            if(window.innerWidth <= 900) {
                resultsCard.scrollIntoView({ behavior: 'smooth' });
            }
        }, 2500); // 2.5 seconds mock delay
    });
});
