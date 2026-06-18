describe('Smoke Test BersatuBantu', () => {
  it('Harus sukses membuka halaman utama web', () => {
    // Cypress otomatis membaca URL Cloud Run dari baseUrl yang dikirim GitHub Actions
    cy.visit('/') 
    cy.get('body').should('be.visible')
  })
})